#!/usr/bin/env nu

# Search available `just` commands interactively, or by <regex>
def main [
  search_term?: string # Regex pattern to match
] {
  if ($search_term | is-empty) {
    let command = (
      just --list 
      | lines
      | drop nth 0
      | to text
      | fzf 
      | str trim | split row " " | first)

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
