#!/usr/bin/env nu

# Search git history
def main [
  search_term: string # The text to search for
] {
  git log -S $search_term --all
}
