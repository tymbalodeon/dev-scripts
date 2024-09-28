#!/usr/bin/env nu

const base_url = "
https://api.github.com/repos/tymbalodeon/dev-scripts/contents"

def "main add" [] {
  print "Add environment from git repo"
}

def filter_by_type [contents: any type: string] {
  $contents 
  | filter {|item| $item.type == $type}
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

  let contents = (http get $path)
  let files = (filter_by_type $contents file)
  let directories = (filter_by_type $contents dir)

  # http get $path
  # | get name
  # | to text
}

def "main remove" [] {
  print "Remove environment"
}

def "main update" [] {
  print "Update (environment)"
}

def main [
  environment?: string
] {
  main list $environment
}
