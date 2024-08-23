#!/usr/bin/env nu

def get_base_directory [environment: string --generated] {
  if $generated {
    if $environment == "dev" {
      return ""
    }

    return $"build/($environment)/"
  } else {
    return $"src/($environment)/"
  }
}

def get_environment_files [environment: string] {
  let src_directory = (
    get_base_directory $environment
  )

  (
    eza
      --all
      --git-ignore
      --oneline
      --recurse
      $src_directory
  ) | split row "\n\n"
  | par-each {
      |row|

      let row = (
        $row
        | lines
      )

      let base_directory = ($row | first)

      if ($base_directory | str ends-with ":") {
        let base_directory = (
          $base_directory
          | str replace --regex ":$" ""
        )

        $row
        | drop nth 0
        | par-each {
            |item|

            $base_directory
            | path join $item
        }
      } else {
        $row
        | filter {
            |item|

            (
              $item
              | path type
            ) != "dir" and not (
              $item in [
                "flake.nix"
                "Justfile"
              ]
            )

        }
      | par-each {
          |file|

          $src_directory
          | path join $file
        }
      }
    }
  | flatten
}

def copy_files [environment: string] {
  let src_files = (
    get_environment_files $environment
  ) | append (
    get_environment_files generic
  )

  let generated_directory = (
    get_base_directory --generated $environment
  )

  if $environment != "dev" {
    rm --force --recursive $generated_directory
  }

  $src_files
  | each {
      |file|

      let filename = (
        $file
        | str replace $"src/($environment)/" ""
        | str replace $"src/generic/" ""
      )

      let generated_file = ($generated_directory | path join $filename)

      mkdir ($generated_file | path parse | get parent)
      cp --recursive $file $generated_file
    }
}

def get_justfile [environment: string] {
  let base_directory = (get_base_directory $environment)

  return $"($base_directory)Justfile"
}

def get_recipe [
  environment: string
  justfile: string
  recipe: string
] {
  return {
    recipe: (just --justfile $justfile --show $recipe)
    environment: $environment
    command: $recipe
  }
}

def get_recipes [environment: string] {
  let justfile = (get_justfile $environment)

  if ($justfile | path exists) {
    let recipes = (
      just --justfile $justfile --summary
      | split row " "
      | par-each {
          |recipe|

          get_recipe $environment $justfile $recipe
      }
    )

    if $environment == "generic" {
      let help_command = "_help"

      $recipes
      | append (get_recipe $environment $justfile $help_command)
    } else {
      $recipes
    }
  } else {
    return []
  }
}

def get_command_name [recipe: record<recipe: string, environment: string>] {
  return (
    $recipe.recipe
    | lines
    | filter {|line| $line | str starts-with "@"}
    | par-each {
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

def get_generated_justfile [environment: string] {
  let base_directory = (get_base_directory $environment --generated)

  return $"($base_directory)Justfile"
}

def get_generatead_scripts_directory [environment: string] {
  let base_directory = (get_base_directory $environment --generated)

  return $"($base_directory)scripts"
}

def merge_justfiles [environment: string] {
  let shared_recipes = (get_recipes "generic")
  let environment_recipes = (get_recipes $environment)

  let recipes = (
    $shared_recipes
    | filter {
        |recipe|

        not ($recipe.command in ($environment_recipes.command))
    } | append $environment_recipes
  )

  let generated_scripts_directory = (
    get_generatead_scripts_directory $environment
  )

  mkdir $generated_scripts_directory

  $recipes
  | par-each {
      |recipe|
      let source_scripts_directory = $"src/($recipe.environment)/scripts"
      let script_file = $"($source_scripts_directory)/($recipe.command).nu"

      cp $script_file $generated_scripts_directory

      open $script_file
      | rg '^use .+\.nu'
      | lines
      | par-each {
          |line|

          let import = (
            $line
            | split row " "
            | get 1
            | path basename
          )

          cp --update (
            $source_scripts_directory
            | path join (
                $line
                | split row " "
                | get 1
                | path basename
              )
          ) $generated_scripts_directory
        }
    }

  let recipes = (
    $recipes
    | sort-by command
  )

  let help_command = "_help"
  mut help_command_index = 0;

  for recipe in ($recipes | enumerate) {
    if ($recipe.item.command) == $help_command {
      $help_command_index = $recipe.index

      break
    }
  }

  let help_command = (
    $recipes
    | filter {|recipe| ($recipe.command) == $help_command}
    | first
  )

  let recipes = (
    $recipes
    | drop nth $help_command_index
  ) | prepend $help_command

  let justfile = (get_generated_justfile $environment)

  (
    $recipes.recipe
    | str join "\n\n"
    | save --force $justfile
  )

  "\n" | save --append $justfile
}

def merge_gitignore [environment: string] {
  let generic = (
    open "src/generic/.gitignore"
    | lines
  )

  let environment_gitignore_path = if $environment == "dev" {
    ".gitignore"
  } else {
    $"($environment)/.gitignore"
  }

  let merged_gitignore = if ($environment_gitignore_path | path exists) {
    $generic
    | append (open $environment_gitignore_path | lines)
    | uniq
    | sort
    | to text
  } else {
    $generic
  }

  $merged_gitignore
  | save --force (
      get_base_directory $environment --generated
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
    | par-each {
        |source_repo|

        let target_repo = (get_target_value $source_repo $target "repo")

        if ($target_repo | is-empty) {
          $source_repo
        } else {
          let $repo_hook_ids = $source_repo.hooks.id

          $source_repo
          | update hooks (
              $source_repo.hooks
              | par-each {
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
                                | get environment
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

def update_pre_commit_update [environment: string] {
  let directory = (get_base_directory $environment)

  try {
    cd $directory
    pdm run pre-commit-update out+err> /dev/null
  }
}

def merge_pre_commit_config [environment: string] {
  [$environment generic]
  | par-each {
      |environment|

      update_pre_commit_update $environment
    }
  | null

  let pre_commit_config_filename = ".pre-commit-config.yaml"

  let generic_config = (
    open (
      get_base_directory generic
      | path join $pre_commit_config_filename
    ) | get repos
  )

  let environment_config_path = (
    (get_base_directory $environment)
    | path join $pre_commit_config_filename
  )

  let generated_config_path = (
    get_base_directory $environment --generated
    | path join ".pre-commit-config.yaml"
  )

  let repos = if (
    $environment_config_path
    | path exists
  ) {
    let environment_config = (open $environment_config_path | get repos)
    let merged_config = (merge_yaml $generic_config $environment_config)

    $environment_config
    | filter {
        |repo|

        (
          not ($repo.repo in $merged_config.repo)
          or (
            (
              (
                $generic_config
                | where repo == $repo.repo
              ).hooks | flatten
            ) != $repo.hooks
          )
        )
      }
  } else {
    $generic_config
  }

  # let repos = {
  #   repos: (
  #     $environment_config
  #     | append $generic_config
  #     | uniq
  #   )
  # }

  # mut existing_repos = []
  # mut final_repos = { repos: [] }

  # for repo in $repos.repos {
  #   if not ($repo.repo in $existing_repos) {
  #     $existing_repos = ($existing_repos | append $repo.repo)
  #     $final_repos.repos = ($final_repos.repos | append $repo)
  #   }
  # }

  # $final_repos.repos = ($final_repos.repos | reverse)

  # $final_repos
  # | to yaml
  # | save --force $generated_config_path
}

def get_flake [environment: string] {
  return $"(get_base_directory $environment)flake.nix"
}

def get_flake_inputs [environment: string] {
  let flake = (get_flake $environment)

  (
    nix eval
      --apply 'builtins.getAttr "inputs"'
      --file $flake
      --json
    | from json
  )
}

def get_generated_flake [environment: string] {
  if $environment == "dev" {
    return (mktemp --tmpdir flake-XXX.nix)
  }

  let base_directory = (get_base_directory $environment --generated)

  return $"($base_directory)flake.nix"
}

def merge_flake_inputs [environment: string generated_flake: string] {
  mut merged_inputs = {}

  for item in ["generic" $environment] {
    let inputs = (get_flake_inputs $item)

    $merged_inputs = ($merged_inputs | merge $inputs)
  }

  let merged_inputs = {inputs: $merged_inputs}

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

  if $environment == "dev" {
    cp $generated_flake flake.nix
    rm $generated_flake
  }
}

def get_flake_packages [environment: string] {
  return (
    open (get_flake $environment)
    | rg --multiline "packages = with pkgs; \\[(\n|.)+\\];"
    | lines
    | drop nth 0
    | drop
    | str trim
  )
}

def get_flake_shell_hook [environment: string] {
  return (
    open (get_flake $environment)
    | rg --multiline "shellHook = ''(\n|.)+'';"
    | lines
    | drop nth 0
    | drop
    | str trim
  )
}

def merge_flake_outputs [environment: string generated_flake: string] {
  let packages = if $environment == "generic" {
     get_flake_packages "generic"
  } else {
    get_flake_packages "generic"
    | append (
        get_flake_packages $environment
      )
    | uniq
    | sort
  }

  let shell_hook = (
    if $environment == "generic" {
      get_flake_shell_hook "generic"
    } else {
      get_flake_shell_hook "generic"
      | append ""
      | append (get_flake_shell_hook $environment)
    } | to text
  )

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

            shellHook = ''\n($shell_hook)'';
          \};
      \}\);
      \};
    \}
  " | alejandra --quiet --quiet
  | save --force $generated_flake
}

def get_modified [
  environment: string
  --generated
] {
  let base_directory = if $generated {
    "build"
  } else {
    "src"
  }

  ls --short-names $base_directory
  | where name == $environment
  | first
  | get modified
}

def is_outdated [environment: string] {
  let src_modified = (get_modified $environment)
  let generated_modified = (get_modified --generated $environment)

  return ($src_modified > $generated_modified)
}

# Build dev environments
def main [environment?: string --skip-dev-flake] {
  let environments = if ($environment | is-empty) {
    eza src
    | lines
  } else {
    [$environment]
  }

  $environments
  | par-each {
      |environment|

      if not (is_outdated $environment) {
        continue
      }

      print $"Building ($environment)..."

      let skip_flake = if $environment == "dev" and $skip_dev_flake {
        true
      } else {
        false
      }

      copy_files $environment
      merge_justfiles $environment
      merge_gitignore $environment
      merge_pre_commit_config $environment

      if not $skip_flake {
        let generated_flake = (get_generated_flake $environment)

        merge_flake_outputs $environment $generated_flake
        merge_flake_inputs $environment $generated_flake
      }
    }
  | null
}
