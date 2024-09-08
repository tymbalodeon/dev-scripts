#!/usr/bin/env nu

export def get_flake_dependencies [flake: string] {
  $flake
  | rg --multiline "packages = .+\\[(\n|[^;])+\\];"
  | lines
  | drop
  | drop nth 0
  | str trim
  | to text
}

# List dependencies
def main [
  dependency?: string
] {
  let dependencies = (get_flake_dependencies (open flake.nix))

  if ($dependency | is-empty) {
    $dependencies
    | table --index false
  } else {
    $dependencies
    | rg --color always $dependency
  }
}
