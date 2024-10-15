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
  | filter {
      |row|

      let path = ($row.path | path parse)

      $path.extension != "lock" and "tests" not-in (
        $path
        | get parent
      )
  }
}

def get_environment_file [environment_files: list file: string] {
  try {
    $environment_files
    | where path == $file
    | first
  } 
}

def get_temporary_environment_file [environment_files: list file: string] {
  let filename = $"XXX-($file | str replace --all '/' '-')"
  let temporary_file = (mktemp --tmpdir $filename)
  let found_file = (get_environment_file $environment_files $file)

  if ($found_file | is-empty) {
    return
  }

  http get (
    $found_file
    | get download_url
  ) | save --force $temporary_file

  $temporary_file
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
  # TODO
  # Handle when environment is generic

  # FIXME .......

  let generic_justfile = if $environment == "generic" {
    let temporary_justfile = (mktemp --tmpdir $"XXX.just")

    open $generic_justfile
    | split row "mod"
    | first
    | str replace "\n\n" ""
    | save --force $temporary_justfile

    $temporary_justfile
  } else {
    $generic_justfile
  }

  let unique_environment_recipes = (
    get_recipes $environment_justfile
    | filter {
        |recipe|

        $recipe not-in (
          get_recipes $generic_justfile
        )
    }
  )

  if ($unique_environment_recipes | is-empty) {
    if $environment == "generic" {
      rm $generic_justfile      
    }

    return
  }

  let merged_justfile = (
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
  )

  if $environment == "generic" {
    rm $generic_justfile      
  }

  $merged_justfile
}

def merge_gitignores [
  generic_gitignore: string
  environment_gitignore: string
] {
  $generic_gitignore
  | lines
  | append ($environment_gitignore | lines)
  | uniq
  | sort
  | to text
}

def "main add" [
  ...environments: string
] {
  for environment in $environments {
    print $"Adding ($environment) environment..."

    let environment_scripts_directory = ([scripts $environment] | path join)

    rm -rf $environment_scripts_directory

    let environment_files = (get_environment_files $environment)

    $environment_files
    | filter {
        |row|

        if $row.name in [.gitignore .pre-commit-config.yaml] {
          return false
        }
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

    let environment_justfile_path = if $environment == "generic" {
      "Justfile"
    } else {
      $"just/($environment).just"
    }

    let temporary_justfile = (
      get_temporary_environment_file $environment_files $environment_justfile_path
    )

    let environment_justfile = (open $temporary_justfile)
  
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
          $temporary_justfile
      ) 

      if ($merged_justfile | is-not-empty) {
        $merged_justfile 
        | save --force Justfile
      }

      mkdir just
      cp $temporary_justfile $environment_justfile_path
    }

    rm $temporary_justfile
    print $"Updated Justfile"

    let tmp_environment_gitignore = (mktemp --tmpdir $"XXX.gitignore")

    let temporary_gitignore = (
      get_temporary_environment_file $environment_files ".gitignore"
    )

    if ($temporary_gitignore | is-not-empty) {
      (
        merge_gitignores
          (open .gitignore)
          (open $temporary_gitignore)
      ) | save --force .gitignore
    }

    print $"Updated .gitignore"

    # TODO
    # Handle pre-commit-config

    if (
      $environment_files
      | filter {
          |file|

          (
            $file.name
            | path parse
            | get extension
          ) == "nix"
        }
      | is-not-empty 
    ) {
      just init
    }
  }
}

def "main list" [
  environment?: string
  path?: string
] {
  let url = (get_base_url)

  if ($environment | is-empty) {
    return (
      http get $url
      | get name
      | to text
    )
  } 

  let files = (
    get_files (
      [$url $environment] 
      | path join
    )
  )

  if ($path | is-empty) {
    return (
      $files
      | get path
      | str replace $"src/($environment)/" ""
      | to text
    )
  }

  let full_path = (
    [src $environment $path] 
    | path join   
  )

  if $full_path in ($files | get path) {
    let file_url = (
      $files
      | where path == $full_path
      | get download_url  
      | first
    )

    return (http get $file_url)
  } 
  
  $files
  | where path =~ $path
  | get path
  | str replace $"src/($environment)/" ""
  | to text
}

def "main remove" [] {
  # TODO
  # detect added environments (as in `just environment update`) and have `remove` get rid of everything except generic
  print "Remove environment"
}

def get_installed_environments [] {
  ls nix
  | get name
  | path parse
  | get stem
  | to text
}

def "main update" [
  ...environments: string
] {
  let environments = if ($environments | is-empty) {
    generic 
    | append (get_installed_environments)
  } else {
    $environments
  }

  main add ...$environments
}

def main [
  environment?: string
] {
  get_installed_environments
}
