#!/usr/bin/env nu

# View the source code for a recipe. If no args are provided, display
# the raw `just` code, otherwise display the code with the args provided
# to `just` applied. Pass `""` as args to see the code when no args are
# provided to a recipe, and to see the code with `just` variables expanded.
export def main [
  recipe: string # The recipe command
] {
  bat $"scripts/($recipe).nu"
}
