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

  let output_scripts_directory = (get_generatead_scripts_directory $type)

  mkdir $output_scripts_directory

  for recipe in $recipes {
    let recipe_type = ($recipe.type)

    if $recipe_type == "dev" {
      continue
    }

    let source_scripts_directory = $"($recipe_type)/scripts"
    let script_file = $"($source_scripts_directory)/($recipe.command).nu"

    cp $script_file $output_scripts_directory
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

  let type_gitignore = (
    open $type_gitignore_path
    | lines
  )

  $main_gitignore
  | append $type_gitignore
  | uniq
  | sort
  | to text
  | save --force $type_gitignore_path
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

  let type_config = (open $type_config_path | get repos)

  let main_config = (
    $main_config
    | each {
      |repo|

      let type_repo = (
        $type_config
        | filter {|type_repo| $type_repo.repo == $repo.repo}
      )

      let type_repo = if ($type_repo | is-empty) {
        $type_repo
      } else {
        $type_repo
        | first
      }

      if ($type_repo | is-empty) {
        $repo
      } else {
        $repo
        | update hooks (
          $repo.hooks
          | each {|hook|
              $hook
              | each {|id|
                if $id.id in ($type_repo.hooks.id) and "types" in ($hook | columns) {
                    let types = (
                      $type_repo.hooks.types
                      | append $id.types
                      | flatten
                      | uniq
                      | sort
                    )

                    $repo | update hooks ($repo.hooks | update types $types) | get hooks
                 } else {
                    $repo
                    | update hooks (
                        $repo.hooks
                        | append ($type_repo.hooks)
                        | uniq
                        | sort
                      )
                    | get hooks
                }
              }
          }
        | uniq
        | flatten
        )
      }
    }
  )

  let main_repos = ($main_config | each {|repo| $repo.repo})

  let type_config = (
    $type_config
    | filter {
        |repo|

        not ($repo.repo in $main_repos)
    }
  )

  let output_config_path = if $type == "dev" {
    ".pre-commit-config.yaml"
  } else {
    $"($type)/out/.pre-commit-config.yaml"
  }

  {
    repos: (
      $main_config
      | append $type_config
      | uniq
    )
  }
  | to yaml
  | save --force $output_config_path

  yamlfmt $output_config_path
}

def get_flake_attribute [type: string attribute: string] {
  let flake = $"(get_base_directory $type)flake.nix"

  (
    nix eval 
      --apply $'builtins.getAttr "($attribute)"'
      --file $flake 
      --json
    | from json
  )  
}

def merge_flake [type: string] {
  mut merged_inputs = {}

  for environment in ["main" $type] {
    let inputs = (get_flake_attribute $environment "inputs")

    $merged_inputs = ($merged_inputs | merge $inputs)
  }

  (
  nix eval 
    --apply builtins.fromJSON
    --expr (
      $merged_inputs 
      | to json
      | to json
    )
  )
}

def copy_files [type: string] {
  merge_justfiles $type
  merge_gitignore $type
  merge_pre_commit_config $type
  merge_flake $type
}

export def main [type?: string] {
  let type = if ($type | is-empty) {
    "main"
  } else {
    $type
  }

  if not ($type in ["dev" "main"]) {
    copy_files $type
  }

  copy_files "dev"
}
