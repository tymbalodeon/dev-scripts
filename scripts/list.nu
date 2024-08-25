#!/usr/bin/env nu

use ./build.nu
use ./build.nu get_environment_files

# List available environments and files
def main [
  environment?: string # List files for environment
] {
  if ($environment | is-empty) {
    ls --short-names src
    | get name
    | to text
  } else {
    build $environment

    # eza --all --tree $"build/($environment)"
    get_environment_files $environment
  }
}
