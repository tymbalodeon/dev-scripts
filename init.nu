#!/usr/bin/env nu

def get_files [
  destination: string
  url: string
] {
  let contents = (
    curl
      --request GET 
    	--header "Accept: application/vnd.github+json" 
    	--header "X-GitHub-Api-Version: 2022-11-28" 
    	--url $url
      err> /dev/null
  ) | from json

  for directory in (
    $contents 
    | filter {|item| $item.type == "dir"}    
  ) {
    get_files $destination $directory.url
  }

  for file in (
    $contents 
    | filter {|item| $item.type == "file"}    
  ) {
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
  }
}

export def main [
  environment?: string # The environment to download
  destination?: string # The name of the destination directory (relative to "~/src/github.com/<username>/")
  --list # List available environments
] {
  let base_url = "https://api.github.com/repos/tymbalodeon/dev-scripts/contents/build"

  if $list {
    return (
      curl $base_url err> /dev/null
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

  get_files $destination $"($base_url)/($environment)"
}
