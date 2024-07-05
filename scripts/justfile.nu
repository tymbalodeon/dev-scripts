#!/usr/bin/env nu

def get_recipes [type: string] {
  let justfile = if $type == "dev" {
    "Justfile"
  } else {
     $"($type)/Justfile"
  }

  return (
    open $justfile
    | split row "\n\n"
    | each {|recipe| {recipe: $recipe type: $type}}
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

def get_justfile_path [type: string] {
  if $type == "dev" {
    "Justfile"
  } else if $type == "main" {
    return "main/Justfile"
  } else {
    return $"($type)/out/Justfile"
  }
}

def get_scripts_folder [type: string] {
  if $type == "dev" {
    return "scripts"
  } else {
    return $"($type)/out/scripts"
  }
}

def merge_justfiles [type: string] {
  let shared_recipes = (get_recipes "main")
  let type_recipes = (get_recipes $type)

  mut recipes = []

  for recipe in $shared_recipes {
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

  let scripts_folder = (get_scripts_folder $type)

  mkdir $scripts_folder

  for recipe in $recipes {
    let type = ($recipe | get type)

    if $type == "dev" {
      continue
    }

    let script_folder = $"($type)/scripts"
    let script_file = $"($script_folder)/($recipe | get command).nu"

    cp $script_file $scripts_folder
  }

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

  let justfile = (get_justfile_path $type)

  (
    $recipes
    | get recipe
    | str join "\n\n"
    | save --force $justfile
  )

  "\n" | save --append $justfile
}

export def main [type?: string command?: string] {
  let type = if ($type | is-empty) {
    "main"
  } else {
    $type
  }

  if $type != "main" {
    merge_justfiles $type
  }

  merge_justfiles "dev"

  let justfile = (get_justfile_path $type)

  if ($command | is-empty) {
    just --justfile $justfile
  } else {
    just --justfile $justfile $command
  }

}
