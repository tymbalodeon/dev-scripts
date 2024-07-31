#!/usr/bin/env nu

export def main [...args: string] {
  cargo run -- ...$args
}
