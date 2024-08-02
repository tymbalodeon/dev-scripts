#!/usr/bin/env nu

# View issues
export def main [
  issue_number?: number # The number of the issue to view
  --close # Close issue
  --create # Create issue
  --develop # Create development branch for issue
  --web # Open the remote repository website in the browser
] {
  if $close {
    gh issue close $issue_number
  } else if $create {
    gh issue create --editor
  } else if $develop {
    gh issue develop --checkout $issue_number
  } else if ($issue_number | is-empty) {
    if $web {
      gh issue list --web
    } else {
      gh issue list
    }
  } else if $web {
    gh issue view $issue_number --web
  } else {
    gh issue view $issue_number
  }
}
