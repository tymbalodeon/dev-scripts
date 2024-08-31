#!/usr/bin/env nu

# View file annotated with version control information
def main [
  _invocation_directory: string
  filename: string
] {
  git blame ($_invocation_directory | path join $filename)
}
