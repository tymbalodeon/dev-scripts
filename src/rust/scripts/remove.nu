#!/usr/bin/env nu

export def main [
  ...dependencies: string # Dependencies to remove
] {
  for dependency in $dependencies {
      cargo remove $dependency
  }
}
