#!/usr/bin/env nu

# List available environments
export def main [] {
  ls --short-names src
  | get name
  | to text
}
