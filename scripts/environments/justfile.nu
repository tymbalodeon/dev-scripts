#!/usr/bin/env nu

# Run an environment Justfile
def main --wrapped [
  environment?: string # The environment whose Justfile to run
  ...args: string # Arguments to pass to the Justfile
] {
  let environment = if ($environment | is-empty) {
    "generic"
  } else {
    $environment
  }

  let justfile = $"src/($environment)/just/($environment).just"

  if ($args | is-empty) {
    just --justfile $justfile --list --list-submodules
  } else {
    just --justfile $justfile ...$args
  }
}
