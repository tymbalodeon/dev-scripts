#!/usr/bin/env nu

# View help text
def main [
  recipe?: string # View help text for recipe
] {
  if ($recipe | is-empty) {
    (
      just
        --color always
        --list
        --list-heading (
          [
            "Available recipes:"
            "(run `just <recipe> --help/-h` for more info)\n"
          ]
          | to text
        )
    )
  } else {
    nu $"./scripts/($recipe).nu" --help
  }
}
