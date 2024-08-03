#!/usr/bin/env nu

const base_path_regex = "build/[a-zA-z]+/"

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
          "path"
        } else {
          "download_url"
        }
      )
    | str replace --regex $base_path_regex ""
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
  destination?: string # The name of the destination directory (relative to "~/src/github.com/<username>/")
  --list # List available environments
  --return-destination # Return the destination after downloading
] {
  let base_url = "https://api.github.com/repos/tymbalodeon/dev-scripts/contents/build"

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

  let destination = if ($destination | is-empty) {
    $environment
  } else {
    $destination
  }

  let destination = (
    $env.HOME
    | path join $"src/github.com/($username)/($destination)"
  )

  let download_urls = (
    get_files $"($base_url)/($environment)" true err> /dev/null
  )

  $download_urls
  | par-each {
      |url|

      let filename = (
        $url
        | split row --regex $base_path_regex
        | last
      )

      let file_path = (
        $destination
        | path join $filename
      )

      mkdir ($file_path | path dirname)

      http get --raw $url
      | save --force $file_path

      print $"Downloaded ($filename)."
    }

  if $return_destination {
    return $destination
  }
}
