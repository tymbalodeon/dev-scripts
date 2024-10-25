#!/usr/bin/env nu

def main [] {
  fd --hidden .pre-commit-config.yaml
  | lines
  | each {
      |file|

      let parent = (
        realpath $file
        | path parse
        | get parent
      )

      cd $parent

      try {
        pdm run pre-commit-update
      } catch {
        pdm venv create --force
        pdm install

        try {
          pdm run pre-commit-update
        }
      }

      print $"Updated ($file)"
    }

  fd --hidden --no-ignore .venv
  | lines
  | each {
      |item|

      rm -rf $item
    }
  | null
}
