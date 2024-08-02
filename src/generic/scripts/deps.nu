#!/usr/bin/env nu

# List dependencies
export def main [
  dependency?: string #
] {
  let dependencies = (
    open flake.nix
    | rg --multiline "packages = .+\\[(\n|.)+\\];"
    | lines
    | drop
    | drop nth 0
    | str trim
    | to text
  )

  let dependencies = if ($dependency | is-empty) {
    return ($dependencies | table --index false)
  } else {
    return (
      $dependencies
      | rg $dependency
    )
  }
}
