#!/usr/bin/env nu

export def main [
  --release # Build in release mode, with optimizations
] {
  if $release {
    cargo build --release
  } else {
    cargo build
  }
}
