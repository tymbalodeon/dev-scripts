#!/usr/bin/env nu

def get_url [url: string --json] {
  let response = (
    http get
      --headers [
        "Accept" "application/vnd.github+json"
        "X-GitHub-Api-Version" "2022-11-28"
      ]
    	--raw $url
  )

  if $json {
    return ($response | from json)
  } else {
    return $response
  }
}

def get_build_filename [path: string] {
  return (
    $path 
    | str replace --regex "build/[a-zA-z]+/" ""
  )
}

def get_files [
  url: string
  download_url: bool
] {
  let contents = (get_url $url --json)

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
          get_build_filename $file
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
  --view-source: string # View contents of file
] {
  let base_url = "https://api.github.com/repos/tymbalodeon/dev-scripts/contents/build"

  if not ($view_source | is-empty) {
    let download_url = (
      get_url $"($base_url)/($environment)/($view_source)" --json 
      | get download_url
    )

    let path = (
      $view_source      
      | path parse
    )

    let language = if ($path | get stem) == ".gitignore" {
      "gitignore"
    } else {
      $path
      | get extension
    }

    return (
      get_url $download_url 
      | bat --force-colorization --language $language
    )
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

  if (
    [$environment $name] 
    | all {|item| ($item | is-empty)}
  ) {
    return (help main)
  }

  let username = (git config github.user)

  let username = if ($username | is-empty) {
    whoami
  } else {
    $username
  }

  let name = if ($name | is-empty) {
    $environment
  } else {
    $name
  }

  let user_directory = (
    $env.HOME
    | path join $"src/github.com/($username)"  
  )

  cd $user_directory
  gh repo create --add-readme --clone --private $name

  let name = (
    $user_directory
    | path join $name
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
        get_build_filename (
          $url
          | split row --regex "trunk/"
          | last
        )
      )

      let file_path = (
        $name
        | path join $filename
      )

      mkdir ($file_path | path dirname)

      http get --raw $url
      | save --force $file_path

      print $"Downloaded \"($filename)\""
    }

  cd $name

  git add .
  git commit --message "chore: initial commit"
  git push

  return $name
}
