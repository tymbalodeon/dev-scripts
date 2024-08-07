#!/usr/bin/env nu

def get_github_url [url: string --json] {
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
  let contents = (get_github_url $url --json)

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

def get_domain [domain: string] {
  if "github" in $domain {
    return "github.com"
  } else if "gitlab" in $domain {
    return "gitlab.com"
  } else {
    exit 1
  }
}

def get_base_url [] {
 return "https://api.github.com/repos/tymbalodeon/dev-scripts/contents/build"
}

# List available environments
def "environment list" [
  environment?: string # The base environment
] {
  let base_url = (get_base_url)

  return (
    if ($environment | is-empty) {
      http get --raw $base_url
      | from json
      | get name
      | to text
    } else {
      get_files $"($base_url)/($environment)" false
    }
  )
}

# View contents of file
def "environment view-source" [
  environment: string # The base environment
  file: string # Filename (relative to environment base)  
] {
  let base_url = (get_base_url)

  let download_url = (
    get_github_url $"($base_url)/($environment)/($file)" --json 
    | get download_url
  )

  let path = (
    $file      
    | path parse
  )

  let language = if ($path | get stem) == ".gitignore" {
    "gitignore"
  } else {
    $path
    | get extension
  }

  return (
    get_github_url $download_url 
    | bat --force-colorization --language $language
  )
}

# Create new repositories from starter development environments
def "environment create" [
  environment?: string # The base environment
  name?: string # The name of the download directory
  --domain: string = "github" # The domain to use for initializing new repositories
] {
  let base_url = (get_base_url)

  if (
    [$environment $name] 
    | all {|item| ($item | is-empty)}
  ) {
    return (help main)
  }

  let username = (git config $"($domain).user")

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
    | path join $"src/(get_domain $domain)/($username)"  
  )

  cd $user_directory

  if $domain == "github" {
    gh repo create --add-readme --clone --private $name
  } 

  let project_path = (
    $user_directory
    | path join $name
  )

  mkdir $project_path
  cd $project_path

  if $domain == "gitlab" {
    git init

    (
      glab repo create 
        --defaultBranch trunk 
        --name $name 
        --private 
        --readme 
    )
  }

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
        $project_path
        | path join $filename
      )

      mkdir ($file_path | path dirname)

      http get --raw $url
      | save --force $file_path

      if ($file_path | path parse | get extension) == "nu" {
        chmod +x $file_path
      }

      print $"Downloaded \"($filename)\""
    }

  git add .
  git commit --message "chore: initial commit"
  git push

  return $project_path
}

def environment [] {
  help environment
}
