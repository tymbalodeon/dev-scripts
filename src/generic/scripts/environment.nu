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

def get_environment_file_url [environment_files: list file: string] {
  try {
    $environment_files
    | where path == $file
    | first
    | get download_url
  } 
}

def get_environment_file [environment_files: list file: string] {
  let url = (get_environment_file_url $environment_files $file)

  if ($url | is-empty) {
    return ""
  }

  http get $url
}

def download_environment_file [
  environment_files: list 
  file: string 
  extension?: string
] {
  let temporary_file = if ($extension | is-not-empty) {
    mktemp --tmpdir --suffix $".($extension)"
  } else {
    mktemp --tmpdir 
  }

  let file_contents = (
    get_environment_file $environment_files $file
  )

  $file_contents
  | save --force $temporary_file

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
  if $environment == "generic" {
    return (
      open $environment_justfile
      | append (
          open $generic_justfile  
          | split row "mod"
          | drop nth 0
          | prepend mod
          | str join
        )
      | to text
    )
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
    return
  }

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

def get_pre_commit_config_repos [config: record<repos: list<any>>] {
  $config
  | get repos
}

def merge_records_by_key [a: list b: list key: string] {
  mut records = []

  for b_record in $b {
    if ($b_record | get $key) in ($a | get $key) {
      let a_record = (
        $a
        | filter {
            |a_record|

            ($a_record | get $key) == ($b_record | get $key)
          }
        | first
      )

      if $key == "repo" {
        let a_hooks = $a_record.hooks
        let b_hooks = $b_record.hooks
        let hooks = (merge_records_by_key $a_hooks $b_hooks "id")

        $records = (
          $records
          | append ($b_record | update hooks $hooks)
        )
      } else {
        $records = (
          $records
          | append ($a_record | merge $b_record)
        )
      }
    } else {
      $records = (
        $records
        | append $b_record
      )
    }
  }

  for a_record in $a {
    if not (($a_record | get $key) in ($records | get $key)) {
      $records = ($records | append $a_record)
    }
  }

  $records
}

def copy_files [environment: string environment_files: list] {
  let environment_scripts_directory = ([scripts $environment] | path join)

  rm -rf $environment_scripts_directory

  $environment_files
  | filter {
      |row|

      $row.name not-in [.gitignore .pre-commit-config.yaml Justfile]
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
}

def copy_justfile [environment: string environment_files: list] {
  let environment_justfile_name = if $environment == "generic" {
    "Justfile"
  } else {
    $"just/($environment).just"
  }

  let environment_justfile_file = (
    download_environment_file 
      $environment_files 
      $environment_justfile_name
  )

  let environment_justfile = (open $environment_justfile_file)

  if (
    $environment_justfile
    | is-not-empty
  ) {
    let merged_justfile = (
      merge_justfiles
        $environment
        Justfile
        $environment_justfile_file
    ) 

    if ($merged_justfile | is-not-empty) {
      $merged_justfile 
      | save --force Justfile
    }
  }

  rm $environment_justfile_file
  print $"Updated Justfile"
}

def copy_gitignore [environment_files: list] {
  let environment_gitignore = (
    get_environment_file $environment_files ".gitignore"
  )

  if ($environment_gitignore | is-not-empty) {
    (
      merge_gitignores
        (open .gitignore)
        $environment_gitignore
    ) | save --force .gitignore
  }

  print $"Updated .gitignore"
}

def copy_pre_commit_config [environment_files: list] {
  let generic_config = (
    get_pre_commit_config_repos (open .pre-commit-config.yaml)
  )

  let environment_config = (
    get_pre_commit_config_repos (
      get_environment_file $environment_files ".pre-commit-config.yaml"
    )
  )

  merge_records_by_key $generic_config $environment_config repo
  print $"Updated .pre-commit-config.yaml"
}

def reload_environment [environment_files: list] {
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

def "main add" [
  ...environments: string
] {
  for environment in $environments {
    print $"Adding ($environment) environment..."

    let environment_files = (get_environment_files $environment)

    copy_files $environment $environment_files
    copy_justfile $environment $environment_files
    copy_gitignore $environment_files
    copy_pre_commit_config $environment_files

    reload_environment $environment_files
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

def get_environments [environments: list<string>] {
  if ($environments | is-empty) {
    "generic"
    | append (get_installed_environments)
    | filter {|environment| $environment | is-not-empty}
  } else {
    $environments
  }
}

def remove_environment_file [environment: string type: string] {
  rm $"($type)/($environment).($type)"

  if (ls $type | length) == 0 {
    rm $type
  }
}

def "main remove" [...environments: string] {
  let environments = (
    get_environments $environments
    | filter {|environment| $environment != "generic"}
  )

  for environment in $environments {
    print $"Removing ($environment)..."

    for type in [just nix] {
      remove_environment_file $environment $type
    }

    rm -rf $"scripts/($environment)"
  }
}

def get_installed_environments [] {
  ls nix
  | get name
  | path parse
  | get stem
  | filter {|environment| $environment in (main list)}
  | to text
}

def "main update" [
  ...environments: string
] {
  let environments = (get_environments $environments)

  main add ...$environments
}

def main [
  environment?: string
] {
  get_installed_environments
}
