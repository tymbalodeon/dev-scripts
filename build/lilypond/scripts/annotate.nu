#!/usr/bin/env nu

# View file annotated with version control information
def main [
  _invocation_directory: string
  filename: string # The file to annotate
] {
  git blame ($_invocation_directory | path join $filename)
}
