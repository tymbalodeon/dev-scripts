#!/usr/bin/env nu

# Search available `just` commands interactively, or by <regex>
def main [
  search_term?: string # Regex pattern to match
] {
  if ($search_term | is-empty) {
    just --list | fzf
  } else {
    just | rg $search_term
  }
}
