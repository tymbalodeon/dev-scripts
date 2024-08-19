#!/usr/bin/env nu

def main [] {
  (
    just
      --color always
      --list
      --list-heading (
        [
          "Available recipes:"
          "(run `just <recipe> --help/-h` for more info)\n"
        ] | to text
      )
  )
}
