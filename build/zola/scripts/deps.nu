#!/usr/bin/env nu

export def get_flake_dependencies [flake: string] {
  $flake
  | rg --multiline "packages = .+(\n|\\[|[^;])+\\]"
  | lines
  | drop nth 0
  | filter {|line| "[" not-in $line and "]" not-in $line}
  | str trim
}

# List dependencies
def main [
  dependency?: string # Search for a dependency
] {

  let dependencies = ("flake.nix" ++ (ls nix | get name))
  | each {
      |flake|

      get_flake_dependencies (open $flake)
    } 
  | flatten
  | uniq
  | sort
  | to text
   
  if ($dependency | is-empty) {
    $dependencies
    | table --index false
  } else {
    $dependencies
    | rg --color always $dependency
  }
}
