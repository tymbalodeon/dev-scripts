#!/usr/bin/env nu

def get_flake_dependencies [flake: string] {
  $flake
  | rg --multiline "packages = .+(\n|\\[|[^;])+\\]"
  | lines
  | drop nth 0
  | filter {|line| "[" not-in $line and "]" not-in $line}
  | str trim
}

export def merge_flake_dependencies [...flakes: string] {
  $flakes
  | each {
      |flake|

      get_flake_dependencies $flake
    } 
  | flatten
  | uniq
  | sort
  | to text
}

# List dependencies
def main [
  dependency?: string # Search for a dependency
] {

  let flakes = (
    "flake.nix" ++ (ls nix | get name)  
    | each {|flake| open $flake}
  )

  let dependencies = (merge_flake_dependencies ...$flakes)
   
  if ($dependency | is-empty) {
    $dependencies
    | table --index false
  } else {
    $dependencies
    | rg --color always $dependency
  }
}
