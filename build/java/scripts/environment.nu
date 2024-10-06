#!/usr/bin/env nu

def get_base_url [] {
  "https://api.github.com/repos/tymbalodeon/dev-scripts/contents"
}

def "main add" [
  environment: string
] {
  print $"Adding ($environment) environment..."

  # TODO change me
  open remove-me-later.json
  | update path {
      |row|

      $row.path
      | str replace $"src/($environment)/" ""
  } | filter {
      |file|

      $file.path
      | path parse
      | get parent
      | is-not-empty
    }
  | select path download_url
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
  let url = ([(get_base_url) src] | path join)

  if ($environment | is-empty) {
    http get $url
    | get name
    | to text
  } else {
    get_files (
      [$url $environment] 
      | path join
    ) | get path
    | str replace $"src/($environment)/" ""
    | to text
  }
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
