#!/usr/bin/env nu

export def find_recipe [_invocation_directory: string] {
  return (
    just --summary
    | split row " "
    | to text
    | (
        fzf
          --preview
          $"bat --force-colorization ($_invocation_directory)/{}.nu"
      )
    | str trim
    | split row " "
    | first
  )
}

# Search available `just` recipes
def main [
  _invocation_directory: string
  search_term?: string # Regex pattern to match
] {
  if ($search_term | is-empty) {
    let command = (find_recipe $_invocation_directory)

    let out = (
      just $command
      | complete
    )

    print (
      if $out.exit_code != 0 {
        just $command --help
      } else {
        print $"(ansi --escape {attr: b})just ($command)(ansi reset)\n"

        $out.stdout
      }
    )
  } else {
    just
    | rg $search_term
  }
}
