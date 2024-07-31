#!/usr/bin/env nu

export def main [
  ...dependencies # Dependencies to add
] {
  cargo add ...$dependencies
}
