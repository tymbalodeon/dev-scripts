#!/usr/bin/env nu

export def parse_git_origin [origin: string] {
  let parsed_origin = if ($origin | str starts-with "git@") {
    $origin
    | parse "git@{domain}.com:{owner}/{repo}.git"
  } else if ($origin | str starts-with "http") {
    $origin
    | str replace --regex "https?://" ""
    | parse "{domain}.com:{owner}/{repo}.git"
  } else if ($origin | str starts-with "ssh://") {
    $origin
    | parse "ssh://git@{domain}.com/{owner}/{repo}.git"
  } else {
    print --stderr $"Unable to parse remote origin: \"($origin)\""

    [{domain: null owner: null repo: null}]
  }

  $parsed_origin
  | first
}

export def main [] {
  parse_git_origin (git remote get-url origin)
  | get domain
}