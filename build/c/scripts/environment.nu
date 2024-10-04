#!/usr/bin/env nu

const base_url = "
https://api.github.com/repos/tymbalodeon/dev-scripts/contents"

def "main add" [] {
  print "Add environment from git repo"
}

def get_files [url: string] {
  let contents = (http get $url)

  $contents
  | filter {|item| $item.type == "file"}
  | append (
      $contents
      | filter {|item| $item.type == "dir"}
      | par-each {|directory| get_files $directory.url}
    )
  | flatten
}

def "main list" [
  environment?: string
] {
  let url = ([$base_url src] | path join)

  let url = if ($environment | is-empty) {
    $url
  } else {
    [$url $environment] 
    | path join
  }
  
  # print (get_files $url)

  http get $url
  | get name
  | to text
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
