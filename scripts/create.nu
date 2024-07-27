#!/usr/bin/env nu

def get_base_directory [type: string --generated] {
  if ($type | is-empty) or ($type == "dev") {
    return ""
  } else {
    if $generated and $type != "main" {
      return $"($type)/out/"
    } else {
      return $"($type)/"
    }
  }
}

def get_justfile [type: string] {
  let base_directory = (get_base_directory $type)

  return $"($base_directory)Justfile"
}

def get_recipes [type: string] {
  let justfile = (get_justfile $type)

  return (
    open $justfile
    | split row "\n\n"
    | each {|recipe| {recipe: $recipe type: $type}}
    | each {|item| $item | insert command (get_command_name $item)}
  )
}

def get_command_name [recipe: record<recipe: string, type: string>] {
  return (
    $recipe.recipe
    | lines
    | filter {|line| $line | str starts-with "@"}
    | each {
        |line|

        $line
        | split row " "
        | first
        | str replace --regex "^@_?" ""
        | str replace ":" ""
      }
    | first
  )
}

export def get_generated_justfile [type: string] {
  let base_directory = (get_base_directory $type --generated)

  return $"($base_directory)Justfile"
}

def get_generatead_scripts_directory [type: string] {
  let base_directory = (get_base_directory $type --generated)

  return $"($base_directory)scripts"
}

def merge_justfiles [type: string] {
  let shared_recipes = (get_recipes "main")
  let type_recipes = (get_recipes $type)

  mut recipes = [];

  let base_recipes = if $type == "dev" {
    $type_recipes
  } else {
    $shared_recipes
  };

  let priority_recipes = if $type == "dev" {
    $shared_recipes
  } else {
    $type_recipes
  };

  for recipe in $base_recipes {
    if not (
      $recipe.command in ($priority_recipes.command)
    ) {
      $recipes = ($recipes | append $recipe)
    }
  }

  let recipes = (
    $recipes
    | append $priority_recipes
  )

  let generated_scripts_directory = (get_generatead_scripts_directory $type)

  mkdir $generated_scripts_directory

  for recipe in $recipes {
    let recipe_type = ($recipe.type)

    if $recipe_type == "dev" {
      continue
    }

    let source_scripts_directory = $"($recipe_type)/scripts"
    let script_file = $"($source_scripts_directory)/($recipe.command).nu"

    cp $script_file $generated_scripts_directory
  }

  let recipes = (
    $recipes
    | sort-by command
  )

  mut help_command_index = 0;

  for recipe in ($recipes | enumerate) {
    if ($recipe.item.command) == "help" {
      $help_command_index = $recipe.index
    }
  }

  let help_command = (
    $recipes
    | filter {|recipe| ($recipe.command) == "help"}
    | first
  )

  let recipes = (
    $recipes
    | drop nth $help_command_index
  ) | prepend $help_command

  let justfile = (get_generated_justfile $type)

  (
    $recipes.recipe
    | str join "\n\n"
    | save --force $justfile
  )

  "\n" | save --append $justfile
}

def merge_gitignore [type: string] {
  let main_gitignore = (
    open "main/.gitignore"
    | lines
  )

  let type_gitignore_path = if $type == "dev" {
    ".gitignore"
  } else {
    $"($type)/.gitignore"
  }

  let merged_gitignore = if ($type_gitignore_path | path exists) {
    $main_gitignore
    | append (open $type_gitignore_path | lines)
    | uniq
    | sort
    | to text
  } else {
    $main_gitignore
  }

  $merged_gitignore
  | save --force (
      get_base_directory $type --generated
      | path join ".gitignore"
    )
}

def get_target_value [source_value: record target: list column: string] {
  let target_value = (
    $target
    | filter {
        |target_value|

        ($target_value | get $column) == ($source_value | get $column)
      }
  )

  return (
    if ($target_value | is-empty) {
      $target_value
    } else {
      $target_value
      | first
    }
  )
}

def merge_yaml [source: list target: list] {
  return (
    $source
    | each {
        |source_repo|

        let target_repo = (get_target_value $source_repo $target "repo")

        if ($target_repo | is-empty) {
          $source_repo
        } else {
          let $repo_hook_ids = $source_repo.hooks.id

          $source_repo
          | update hooks (
              $source_repo.hooks
              | each {
                  |source_hook|

                  let target_hook = (
                    get_target_value $source_hook $target_repo.hooks "id"
                  )

                  if ($target_hook | is-empty) {
                    $source_hook
                  } else {
                    mut merged_hook = $source_hook

                    for column in (
                      $source_hook
                      | reject id
                      | columns
                    ) {
                      let value = ($source_hook | get $column)

                      $merged_hook = (
                        $source_hook
                        | merge (
                          {
                            $column: (
                              if (
                                $value
                                | describe --detailed
                                | get type
                              ) == "list" {
                                $value
                                | append (
                                  $target_hook
                                  | get $column
                                )
                                | uniq
                              } else {
                                $target_hook
                                | get $column
                              }
                            )
                          }
                        )
                        | merge $target_hook
                      )
                    }

                    $merged_hook
                  }
                }
                | append (
                  $target_repo.hooks
                  | filter {
                      |target_hook|

                      not ($target_hook.id in $repo_hook_ids)
                    }
                )
            )
        }
      }
  )
}

def merge_pre_commit_config [type: string] {
  let main_config = (
    open "main/.pre-commit-config.yaml"
    | get repos
  )

  let type_config_path = if $type == "dev" {
    ".pre-commit-config.yaml"
  } else {
    $"($type)/.pre-commit-config.yaml"
  }

  let type_config = if ($type_config_path | path exists) {
    let type_config = (open $type_config_path | get repos)
    let merged_config = (merge_yaml $main_config $type_config)
    let main_repos = ($merged_config | each {|repo| $repo.repo})

    $type_config
    | filter {
        |repo|

        (
          not ($repo.repo in $merged_config.repo)
          or ((($main_config | where repo == $repo.repo).hooks | flatten) != $repo.hooks)
        )
      }
  } else {
    []
  }

  let generated_config_path = if $type == "dev" {
    ".pre-commit-config.yaml"
  } else {
    $"($type)/out/.pre-commit-config.yaml"
  }

  let repos = {
    repos: (
      $type_config
      | append $main_config
      | uniq
    )
  }

  mut existing_repos = []
  mut final_repos = { repos: [] }

  for repo in $repos.repos {
    if not ($repo.repo in $existing_repos) {
      $existing_repos = ($existing_repos | append $repo.repo)
      $final_repos.repos = ($final_repos.repos | append $repo)
    }
  }

  $final_repos.repos = ($final_repos.repos | reverse)

  $final_repos
  | to yaml
  | save --force $generated_config_path
}

def get_flake [type: string] {
  return $"(get_base_directory $type)flake.nix"
}

def get_flake_inputs [type: string] {
  let flake = (get_flake $type)

  (
    nix eval
      --apply $'builtins.getAttr "inputs"'
      --file $flake
      --json
    | from json
  )
}

def get_generated_flake [type: string] {
  let base_directory = (get_base_directory $type --generated)

  return $"($base_directory)flake.nix"
}

def merge_flake_inputs [type: string] {
  mut merged_inputs = {}

  for environment in ["main" $type] {
    let inputs = (get_flake_inputs $environment)

    $merged_inputs = ($merged_inputs | merge $inputs)
  }

  let merged_inputs = {inputs: $merged_inputs}

  let generated_flake = if $type in ["dev" "main"] {
   ".flake.temp.nix"
  } else {
    get_generated_flake $type
  }

  let inputs = (
    nix eval
      --apply builtins.fromJSON
      --expr (
        $merged_inputs
        | to json
        | to json
      )
    | alejandra --quiet --quiet
    | lines
    | drop nth 0
    | drop
  )

  "\{\n"
  | append $inputs
  | append "\n"
  | append (
    open $generated_flake
    | lines
    | drop nth 0
  ) | save --force $generated_flake

  alejandra --quiet --quiet $generated_flake

  if $type in ["dev" "main"] {
    cp $generated_flake flake.nix
    rm $generated_flake
  }
}

def get_flake_packages [type: string] {
  return (
    open (get_flake $type)
    | rg --multiline "packages = with pkgs; \\[(\n|.)+\\];"
    | lines
    | drop nth 0
    | drop
    | str trim
  )
}

def get_flake_shell_hook [type: string] {
  return (
    open (get_flake $type)
    | rg --multiline "shellHook = ''(\n|.)+'';"
    | lines
    | drop nth 0
    | drop
    | str trim
  )
}

def merge_flake_outputs [type: string] {
  let packages = if $type in ["dev" "main"] {
     get_flake_packages "main"
  } else {
    get_flake_packages "main"
    | append (
        get_flake_packages $type
      )
    | uniq
    | sort
  }

  let shell_hook = (
    if $type in ["dev" "main"] {
      get_flake_shell_hook "main"
    } else {
      get_flake_shell_hook "main"
      | append (get_flake_shell_hook $type)
    } | to text
  )

  let generated_flake = if $type in ["dev" "main"] {
   ".flake.temp.nix"
  } else {
    get_generated_flake $type
  }

  $"
    \{
      outputs = \{
        nixpkgs,
        nushell-syntax,
        ...
      \}: let
        supportedSystems = [
          \"x86_64-darwin\"
          \"x86_64-linux\"
        ];

        forEachSupportedSystem = f:
          nixpkgs.lib.genAttrs supportedSystems
          \(system:
            f \{
              pkgs = import nixpkgs \{inherit system;\};
            \}\);
      in \{
        devShells = forEachSupportedSystem \(\{pkgs\}: \{
          default = pkgs.mkShell \{
            packages = with pkgs; [
              ($packages | to text)
            ];

            shellHook = ''\n($shell_hook)\n'';
          \};
      \}\);
      \};
    \}
  " | alejandra --quiet --quiet
  | save --force $generated_flake
}

def merge_flake [type: string] {
  merge_flake_outputs $type
  merge_flake_inputs $type
}

def copy_files [type: string skip_flake: bool] {
  merge_justfiles $type
  merge_gitignore $type
  merge_pre_commit_config $type

  if not $skip_flake {
    merge_flake $type
  }
}

export def main [type?: string --skip-dev-flake] {
  let type = if ($type | is-empty) {
    "main"
  } else {
    $type
  }

  if not ($type in ["dev" "main"]) {
    copy_files $type false
  }

  copy_files "dev" $skip_dev_flake
}
