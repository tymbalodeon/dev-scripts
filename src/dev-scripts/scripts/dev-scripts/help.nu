#!/usr/bin/env nu

# View help text
def main [
  recipe?: string # View help text for recipe
] {
  if ($recipe | is-empty) {
    (
      just
        --color always
        --justfile dev-scripts.just
        --list
    )
  } else {
    nu $"../scripts/dev-scripts/($recipe).nu" --help
 }
}
