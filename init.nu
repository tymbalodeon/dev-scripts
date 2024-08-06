#!/usr/bin/env nu

def get_files [
  url: string
  download_url: bool
] {
  let contents = (
    http get
      --headers [
        "Accept" "application/vnd.github+json"
        "X-GitHub-Api-Version" "2022-11-28"
      ]
    	--raw $url
  ) | from json

  return (
    $contents
    | filter {|item| $item.type == "file"}
    | get (
        if $download_url {
          "download_url"
        } else {
          "path"
        }
      )
    | each {
        |file|

        if $download_url {
          $file
        } else {
          $file
          | str replace --regex "build/[a-zA-z]+/" ""
        }
      }
    | append (
      $contents
      | filter {|item| $item.type == "dir"}
      | each {
          |item|

          get_files $item.url $download_url
        }
      )
    | flatten
    | to text
  )
}

export def main [
  environment?: string # The environment to download
  name?: string # The name of the download directory
  --list # List available environments
  --return-name # Return the destination directory after downloading
] {
  let base_url = "https://api.github.com/repos/tymbalodeon/dev-scripts/contents/build"

  if not (
    [$environment $name] 
    | any {|item| not ($item | is-empty)}
  ) {
    return (help main)
  }

   if $list {
    if ($environment | is-empty) {
      return (
        http get --raw $base_url
        | from json
        | get name
        | to text
      )
    } else {
      return (get_files $"($base_url)/($environment)" false)
    }
  }

  let username = (git config github.user)

  let name = if ($name | is-empty) {
    $environment
  } else {
    $name
  }

  let name = (
    $env.HOME
    | path join $"src/github.com/($username)/($name)"
  )

  let download_urls = (
    get_files $"($base_url)/($environment)" true err> /dev/null
    | lines
    | filter {|line| not ($line | is-empty)}
  )

  $download_urls
  | par-each {
      |url|

      let filename = (
        $url
        | split row --regex "trunk/"
        | last
      )

      let file_path = (
        $name
        | path join $filename
      )

      mkdir ($file_path | path dirname)

      http get --raw $url
      | save --force $file_path

      print $"Downloaded ($filename)."
    }

  if $return_name {
    return $name
  }
}
