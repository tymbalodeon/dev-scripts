#!/usr/bin/env nu

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
      }
    | first
  )
}

def compare_recipes [
  a: record<recipe: string, type: string> 
  b?: record<recipe: string, type: string>
] {
  print $a $b
  print "\n"

  if ($b | is-empty) {
    return $a
  }

  let a_command_name = (get_command_name $a) 
  let b_command_name = (get_command_name $b) 
  
  if $a_command_name > $b_command_name {
    return $a
  } else {
    return $b
  }
}

export def main [] {
  mut final_recipes = []

	let recipes = (
		open Justfile 
		| split row "\n\n"
    | each {|item| {recipe: $item type: "main"}}
	) | append (
		open python/Justfile 
		| split row "\n\n"
    | each {|item| {recipe: $item type: "python"}}
	) 

  let number_of_recipes = ($recipes | length)
  
  for item in ($recipes | enumerate) {
    let a_recipe = ($item.item)
    let next_index = ($item.index + 1)

    if $next_index < $number_of_recipes {
      let b_recipe = ($recipes | get $next_index)

      for recipe in (compare_recipes $a_recipe $b_recipe) {
        $final_recipes = ($final_recipes | append $recipe)
      }
    } else {
      for recipe in (compare_recipes $a_recipe) {
        $final_recipes = ($final_recipes | append $recipe)
      }
    }
  }
}
