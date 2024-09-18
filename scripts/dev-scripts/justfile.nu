#!/usr/bin/env nu

use ./build.nu get_build_directory
use ./build.nu get_justfile

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

  let justfile = (get_justfile (get_build_directory $environment))

  if ($args | is-empty) {
    just --justfile $justfile --list --list-submodules
  } else {
    just --justfile $justfile ...$args
  }
}
