#!/usr/bin/env nu

# Close issue
def "main close" [
  issue_number: number # Issue number
] {
  # let issue_title = (
  #   gh issue view $issue_number --json title
  #   | from json
  #   | get title
  # )

  # let issue_branch = $"($issue_number)-($issue_title)"

  # if (git branch --show-current) != $issue_branch {
  #   git checkout $issue_branch

  #   if not (git status --short | is-empty) {
  #     return "Please"
  #   }
  # }

  gh issue close $issue_number

  # git branch --delete $issue_branch
}

# Create issue
def "main create" [] {
  let last_issue_number = (
    gh issue list --json number    
    | from json
    | get number
    | math max
  )

  gh issue create --editor

  main develop ($last_issue_number + 1)
}

# Create development branch for issue
def "main develop" [
    issue_number: number # Issue number
] {
  gh issue develop --checkout $issue_number
}

# List issues
def "main list" [
  --web # List issues in the browser
] {
  if $web {
    gh issue list --web
  } else {
    gh issue list
  }
}

# View issues
def "main view" [
  issue_number: number # Issue number
  --web # View issues in the browser
] {
  if $web {
    gh issue view $issue_number --web
  } else {
    gh issue view $issue_number
  }
}

# View issues
export def main [
  issue_number?: number # The number of the issue to view
  --web # Open the remote repository website in the browser
] {
  if ($issue_number | is-empty) {
    if $web {
      main list --web
    } else {
      main list 
    }
  } else {
    if $web {
      main view $issue_number --web
    } else {
      main view $issue_number
    }
  }
}
