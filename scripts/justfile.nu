#!/usr/bin/env nu

def get_recipes [justfile: string name: string] {
  return (
    open $justfile
    | split row "\n\n"
    | each {|recipe| {recipe: $recipe type: $name}}
    | each {|item| $item | insert command (get_command_name $item)}
  )
}

def get_command_name [recipe: record<recipe: string, type: string>] {
  return (
    $recipe
    | get recipe
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

export def main [type: string] {
  let main_recipes = (get_recipes "main/Justfile" "main")
  let type_recipes = (get_recipes $"($type)/Justfile" $type)

  mut recipes = []
  
  for recipe in $main_recipes {
    if not (
      ($recipe | get command) in ($type_recipes | get command)
    ) {
      $recipes = ($recipes | append $recipe)
    }
  }

  let recipes = (
    $recipes 
    | append $type_recipes
  )

  let output_folder = $"($type)/out"
  let scripts_folder = $"($output_folder)/scripts/"

  mkdir $scripts_folder

  for recipe in $recipes {
    let script_file = $"($recipe | get type)/scripts/($recipe | get command).nu"

    cp $script_file $scripts_folder
  }

  let output_justfile = $"($output_folder)/Justfile"

  let recipes = (
    $recipes 
    | sort-by command
  ) 

  mut help_command_index = 0;

  for recipe in ($recipes | enumerate) {
    if ($recipe.item | get command) == "help" {
      $help_command_index = $recipe.index
    }
  }

  let help_command = (
    $recipes
    | filter {|recipe| ($recipe | get command) == "help"}
    | first
  )

  let recipes = (
    $recipes 
    | drop nth $help_command_index
  ) | prepend $help_command

  (
    $recipes
    | get recipe
    | str join "\n\n"
    | save --force $output_justfile
  )

  just --justfile $output_justfile
  
}
