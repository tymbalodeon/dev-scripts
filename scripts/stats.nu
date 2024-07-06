#!/usr/bin/env nu

# View repository analytics
export def main [] {
  tokei --hidden --no-ignore --sort lines
}
