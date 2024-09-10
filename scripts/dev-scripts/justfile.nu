#!/usr/bin/env nu

use ./build.nu get_build_directory

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

  let build_directory = (get_build_directory $environment)
  let justfile = $"($build_directory)/just/($environment).just"

  just --justfile $justfile ...$args
}
