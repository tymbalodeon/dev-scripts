#!/usr/bin/env nu

def get_base_url [] {
  "https://api.github.com/repos/tymbalodeon/dev-scripts/contents/src"
}

def "main add" [
  environment: string
] {
  print $"Adding ($environment) environment..."

  let environment_scripts_directory = ([scripts $environment] | path join)

  rm -rf $environment_scripts_directory

  get_files ([(get_base_url) $environment] | path join)
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
  | par-each {
      |file|

      let parent = ($file.path | path parse | get parent)

      if ($parent | is-not-empty) {
        mkdir $parent
      }

      print $"Downloading ($file.path)..."

      http get $file.download_url
      | save --force $file.path
    }

  
  # merge Justfile
  # merge .gitignore
  # direnv reload
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
  let url = (get_base_url)

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
