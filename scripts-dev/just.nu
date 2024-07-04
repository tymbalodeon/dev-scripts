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
    | each {|line| $line | split row " " | first}
    | first
  )
}

export def main [type: string] {
  let type_justfile = $"($type)/Justfile"

  let main_recipes = (get_recipes "Justfile" "main")
  let type_recipes = (get_recipes $"($type_justfile)-($type)" $type)

  mut recipes = []
  
  for recipe in $main_recipes {
    if not (
      ($recipe | get command) in ($type_recipes | get command)
    ) {
      $recipes = ($recipes | append $recipe)
    }
  }

  echo (
    $recipes 
    | append $type_recipes
    | sort-by command
    | get recipe
    | str join "\n\n"
  ) | save --force $type_justfile
}
