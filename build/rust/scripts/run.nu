#!/usr/bin/env nu

def main [...args: string] {
  cargo run -- ...$args
}
