#!/usr/bin/env nu

use ./hosts.nu is_nixos

# Rollback to a previous generation
export def main [
  generation_id: int
] {
  if (is_nixos) {
    exit 1
  }

  let path = (
    home-manager generations
    | lines
    | each {
        |line|

        let row = ($line | split row " ")
        let id = ($row | get 4)
        let path = ($row | last)

        {id: $id, path: $path}
    } | where id == ($generation_id | into string)
    | get path
    | first
  )

  ^$"($path)/activate"
}
