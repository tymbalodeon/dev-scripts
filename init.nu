#!/usr/bin/env nu

def get_files [
  destination: string
  url: string
] {
  let contents = (
    http get
      --headers [
        "Accept" "application/vnd.github+json"
        "X-GitHub-Api-Version" "2022-11-28"
      ]
    	--raw $url
  ) | from json

  for directory in (
    $contents
    | filter {|item| $item.type == "dir"}
  ) {
    get_files $destination $directory.url
  }

  $contents
  | filter {|item| $item.type == "file"}
  | par-each {
      |file|
      let filename = (
        $file.download_url
        | split row --regex "build/[a-zA-z]+/"
        | last
      )

      let file_path = (
        $destination
        | path join $filename
      )

      mkdir ($file_path | path dirname)

      http get --raw $file.download_url
      | save --force $file_path

      print $"Downloaded ($filename)."
    }
}

export def main [
  environment?: string # The environment to download
  destination?: string # The name of the destination directory (relative to "~/src/github.com/<username>/")
  --list # List available environments
  --return-destination # Return the destination after downloading
] {
  let base_url = "https://api.github.com/repos/tymbalodeon/dev-scripts/contents/build"

  if $list {
    return (
      http get --raw $base_url
      | from json
      | get name
      | to text
    )
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

  (
    get_files
      $destination
      $"($base_url)/($environment)"
      err> /dev/null
  )

  if $return_destination {
    return $destination
  }
}
