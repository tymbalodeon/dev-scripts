#!/usr/bin/env nu

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

  let base_directory = if $environment == "dev" {
    ""
  } else {
    $"build/($environment)/"
  }

  print (pwd)
  just --justfile $"($base_directory)Justfile" ...$args
}
