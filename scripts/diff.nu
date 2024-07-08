#!/usr/bin/env nu

export def main [] {
  print "Implement me!"

  for file in (ls).name {
    do --ignore-errors {
      delta $"main/($file)" $"python/($file)"
    }
  }
}
