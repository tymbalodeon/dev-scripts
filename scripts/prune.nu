#!/usr/bin/env nu

# Collect garbage and remove old generations
export def main [
  --all # Remove all old generations
  --older-than: string # Remove generations older than this amount
] {
  if $all {
    nix-collect-garbage --delete-old
  } else if not ($older_than | is-empty) {
    nix-collect-garbage --delete-older-than $older_than
  } else {
    nix-collect-garbage
  }
}
