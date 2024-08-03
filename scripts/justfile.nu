#!/usr/bin/env nu

# Run an environment Justfile
export def main [
  environment?: string # The environment whose Justfile to run
  ...args: string # Arguments to pass to the Justfile
] {
  let environment = if ($environment | is-empty) {
    "generic"
  } else {
    $environment
  }

  just --justfile $"build/($environment)/Justfile" ...$args
}
