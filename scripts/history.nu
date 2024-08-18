#!/usr/bin/env nu

def --wrapped "main commits" [
  ...args: string
] {
  cog log ...$args
}

# Search git history
def main [
  invocation_directory: string  
  filename: string # Show file history
] {
  git log --patch ($invocation_directory | path join $filename)
}
