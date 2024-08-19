#!/usr/bin/env nu

def --wrapped cog-log [...args: string] {
  let args = (
    $args 
    | window 2 --stride 2
    | filter {
        |arg|

        let value = ($arg | last)
        let type = ($value | describe)

        if $type == "string" {
          not ($value | is-empty)
        } else if $type == "bool" {
          $value
        }
      }
    | flatten
  )

  cog log ...$args
}

# View commit history
def main [
  --author: string # Filter on commit author
  --breaking-change # Filter BREAKING CHANGE commits
  --no-error # Omit error on the commit log
  --oneline # View commits on one line
  --scope: string # Filter on commit scope
  --type: string # Filter on commit type
] {
  if $oneline {
    (
      ^git log
        --pretty=format:'%C(auto)%h%d%C(reset) %C(dim)%ar%C(reset) %C(bold)%s%C(reset) %C(dim blue)(%an)%C(reset)'
        --graph
    )
  } else {
    (
      cog-log
        --author $author 
        --breaking-change $breaking_change
        --no-error $no_error 
        --scope $scope 
        --type $type
    )
  }
}
