#!/usr/bin/env nu

const base_url = "https://api.github.com/repos/tymbalodeon/dev-scripts/contents"

def "main add" [] {
  print "Add environment from git repo"
}

def "main list" [
  environment?: string
] {
  let path = ([$base_url src] | path join)

  let path = if ($environment | is-empty) {
    $path
  } else {
    [$path $environment] 
    | path join
  }

  # let files = (http get $path)

  http get $path
  | get name
  | to text
}

def "main remove" [] {
  print "Remove environment"
}

def "main update" [] {
  print "Update (environment)"
}

def main [] {}
