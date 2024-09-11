#!/usr/bin/env nu

use ./build.nu

# List available environments and files
def main [
  environment?: string # List files for environment
  path?: string # View specific path in environment
] {
  if ($environment | is-empty) {
    ls --short-names src
    | get name
    | sort
    | to text
  } else {
    build $environment

    let build_path = (
      "build"
      | path join $environment
    )

    let path = if ($path | is-empty) {
      $build_path
    } else {
      $build_path
      | path join $path
    }

    if ($path | path type) == "dir" {
      eza --all --tree $path
    } else {
      bat $path
    }
  }
}
