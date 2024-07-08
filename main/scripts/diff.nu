#!/usr/bin/env nu

export def main [] {
  for file in (ls).name {
    do --ignore-errors {
      delta $"main/($file)" $"python/($file)"
    }
  }
}
