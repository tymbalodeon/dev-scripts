#!/usr/bin/env nu

def get_base_url [] {
  "https://api.github.com/repos/tymbalodeon/dev-scripts/contents/src"
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

def get_environment_files [environment: string] {
  get_files ([(get_base_url) $environment] | path join)
  | update path {
      |row|

      $row.path
      | str replace $"src/($environment)/" ""
  } 
}

def get_environment_file [environment_files: list file: string] {
  try {
    $environment_files
    | where path == $file
    | first
  } catch {
    null
  }
}

def get_recipes [justfile: string] {
  (
    just
      --justfile $justfile
      --summary
    | split row " "
  )
}

def create_environment_recipe [environment: string recipe: string] {
  let documentation = $"# Alias for `($environment) ($recipe)`"
  let declaration = $"@($recipe) *args:"
  let content = $"    just ($environment) ($recipe) {{ args }}"

  [$documentation $declaration $content]
  | str join "\n"
}

def merge_justfiles [
  environment: string
  generic_justfile: string
  environment_justfile: string
] {
  let unique_environment_recipes = (
    get_recipes $environment_justfile
    | filter {
        |recipe|

        $recipe not-in (
          get_recipes $generic_justfile
        )
    }
  )

  open $generic_justfile
  | append (
      $"mod ($environment) \"just/($environment).just\""
      | append (
          $unique_environment_recipes
          | each {
              |recipe|

              create_environment_recipe $environment $recipe
            }
        )
    | str join "\n\n"
    )
  | to text
}

def "main add" [
  environment: string
] {
  print $"Adding ($environment) environment..."

  let environment_scripts_directory = ([scripts $environment] | path join)

  rm -rf $environment_scripts_directory

  let environment_files = (get_environment_files $environment)

  get_environment_files $environment 
  | filter {
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

  let environment_justfile_path = $"just/($environment).just"
  let tmp_environment_justfile = (mktemp --tmpdir $"($environment)-XXX.just")

  http get (
    get_environment_file $environment_files $environment_justfile_path
    | get download_url
  ) | save --force $tmp_environment_justfile

  let environment_justfile = (open $tmp_environment_justfile)
  
  if (
    $environment_justfile
    | is-not-empty
  ) {
    $environment_justfile
    | save --force $environment_justfile_path

    let merged_justfile = (
      merge_justfiles
        $environment
        Justfile
        $tmp_environment_justfile
    ) 

    $merged_justfile 
    | save --force Justfile

    mkdir just
    cp $tmp_environment_justfile $environment_justfile_path
  }

  rm $tmp_environment_justfile
  print $"Updated Justfile"

  # merge .gitignore
  # direnv reload
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
