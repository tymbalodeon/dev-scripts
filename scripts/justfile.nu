#!/usr/bin/env nu

use ./build.nu get_base_directory

# Run an environment Justfile
def main [
  environment?: string # The environment whose Justfile to run
  ...args: string # Arguments to pass to the Justfile
] {
  let environment = if ($environment | is-empty) {
    "generic"
  } else {
    $environment
  }

  let base_environment = (get_base_directory $environment)
  let justfile = $"($base_environment)/just/($environment).just"

  just --justfile $justfile ...$args
}
