#!/usr/bin/env nu

use ./build.nu

# List available environments and files
export def main [
  environment?: string # List files for environment
] {
  if ($environment | is-empty) {
    ls --short-names src
    | get name
    | to text
  } else {
    build $environment

    eza --all --tree $"build/($environment)"
  }
}
