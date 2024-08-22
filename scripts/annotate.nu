#!/usr/bin/env nu

# View file annotated with version control information
def main [
  invocation_directory: string
  filename: string
] {
  git blame ($invocation_directory | path join $filename)
}
