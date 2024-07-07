#!/usr/bin/env nu

use ./create.nu get_generated_justfile

export def main [type: string command?: string] {
  let justfile = (get_generated_justfile $type)

  if ($command | is-empty) {
    just --justfile $justfile
  } else {
    just --justfile $justfile $command
  }
}
