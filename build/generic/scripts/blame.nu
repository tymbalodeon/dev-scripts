#!/usr/bin/env nu

# View `git blame` for a file
def main [
  invocation_directory: string  
  filename: string
] {
  git blame ($invocation_directory | path join $filename)
}
