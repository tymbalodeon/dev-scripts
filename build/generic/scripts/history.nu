#!/usr/bin/env nu

# Search git history
def main [
  invocation_directory: string  
  filename: string
] {
  git log --patch ($invocation_directory | path join $filename)
}
