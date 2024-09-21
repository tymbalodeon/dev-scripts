#!/usr/bin/env nu

def get_source_directory [environment: string] {
  [src $environment] 
  | path join
}

export def get_build_directory [environment: string] {
  if $environment == "dev-scripts" {
    ""
  } else {
    [build $environment]
    | path join
  }
}

export def get_settings [environment: string] {
  {
    environment: $environment
    generic_source_directory: (get_source_directory generic)
    generic_build_directory: (get_build_directory generic)
    source_directory: (get_source_directory $environment)
    build_directory: (get_build_directory $environment)
  }
}

def get_modified [
  environment: string
  --generated
] {
  let base_directory = if $generated {
    if $environment == "dev-scripts" {
      pwd
    } else {
      get_build_directory $environment
    }
  } else {
    get_source_directory $environment
  }

  ls --directory $base_directory
  | get modified
}

def filter_files [files: list<string> excluded_patterns: list<string>] {
  $files
  | filter {
      |file|

      for item in $excluded_patterns {
        if ($item | str ends-with "/") and (
            $item in ($file | path parse | get parent)
        ) or ($item in $file) {
          return false
        }
      }

      true
    }
}

def get_files [directory: string] {
  let directory = if ($directory | is-empty) {
    "./"
  } else {
    $directory
  }

  let files = (
    fd --hidden --ignore --exclude .git "" $directory
    | lines
    | filter {
        |line|

        not ($line | str ends-with "/")
      }
    | each {
        |line|

        $line
        | str replace --regex "^./" ""
    }
  )

  let files = if $directory == "./" {
    filter_files $files [build/ src/]
  } else {
    $files
  }

  filter_files $files [
    CHANGELOG.md
    flake.lock
    pdm.lock
  ]
}

def get_environment_files [
  settings: record<
    environment: string
    generic_source_directory: string
    generic_build_directory: string
    source_directory: string
    build_directory: string
  >
  --build
] {
  let source_directory = if $build {
    $settings.build_directory
  } else {
    $settings.source_directory
  }

  let generic_directory = if $build {
    $settings.generic_build_directory
  } else {
    $settings.generic_source_directory
  }

  let files = (get_files $source_directory)

  let files = if $settings.environment == "generic" or $build {
    $files
  } else {
    $files
    | append (get_files $generic_directory)
  }

  $files
  | filter {|file| "/tests" not-in $file}
}

def get_build_path [environment: string path: string] {
  get_build_directory $environment
  | path join (
    $path
    | str replace --regex "src/[a-zA-Z-_]+/" ""
  )
}

def get_source_directories [
  source_files: list<string>
  settings: record<
    environment: string
    generic_source_directory: string
    generic_build_directory: string
    source_directory: string
    build_directory: string
  >
] {
  $source_files
  | path dirname
  | uniq
  | filter {|directory| $directory != $settings.source_directory}
  | each {|directory| get_build_path $settings.environment $directory}
  | uniq
}

def copy_source_files [
  source_files: list<string>
  settings: record<
    environment: string
    generic_source_directory: string
    generic_build_directory: string
    source_directory: string
    build_directory: string
  >
] {
  let directories = (get_source_directories $source_files $settings)

  for directory in $directories {
    mkdir $directory
  }

  let source_files = (
    $source_files
    | filter {
        |file|

        ($file | path basename) not-in [
          .gitignore 
          .pre-commit-config.yaml
          flake.nix
          Justfile
        ] and ($file | path parse | get extension) != "just"
      }
    | filter {|item| ($item | path type) != dir}
  )

  for file in $source_files {
    let build_path = (get_build_path $settings.environment $file)

    cp $file $build_path

    print $"Updated ($build_path)"
  }
}

export def get_justfile [base_directory: string] {
  $base_directory
  | path join Justfile
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

export def merge_justfiles [
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

def copy_justfile [
  settings: record<
    environment: string
    generic_source_directory: string
    generic_build_directory: string
    source_directory: string
    build_directory: string
  >
] {
  let generic_justfile = (get_justfile $settings.generic_source_directory)

  let environment_justfile = (
    $settings.source_directory
    | path join $"just/($settings.environment).just"
  )

  if (
    $environment_justfile
    | path exists
  ) {
    let build_justfile = (get_justfile $settings.build_directory)

    (
      merge_justfiles
        $settings.environment
        $generic_justfile
        $environment_justfile
    ) | save --force $build_justfile

    print $"Updated ($build_justfile)"

    let environment_justfile_directory = (
      $settings.build_directory 
      | path join "just"
    )

    mkdir $environment_justfile_directory
    cp $environment_justfile $environment_justfile_directory

    print $"Updated (get_build_path $settings.environment $environment_justfile)"
  } else {
    let build_path = ($settings.build_directory | path join Justfile)

    cp $generic_justfile $build_path

    print $"Updated ($build_path)"
  }
}

def get_gitignore [source_directory: string] {
  let path = (
    $source_directory
    | path join .gitignore
  )

  if (
    $path
    | path exists
  ) {
    open $path
  } else {
    ""
  }
}

export def merge_gitignores [
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

def copy_gitignore [
  settings: record<
    environment: string
    generic_source_directory: string
    generic_build_directory: string
    source_directory: string
    build_directory: string
  >
] {
  let build_gitignore = (
    $settings.build_directory
    | path join ".gitignore"
  )

  (
    merge_gitignores
      (get_gitignore $settings.generic_source_directory)
      (get_gitignore $settings.source_directory)
  ) | save --force $build_gitignore

  print $"Updated ($build_gitignore)"
}

def update_pre_commit_update [environment: string] {
  let directory = (get_source_directory $environment)

  try {
    cd $directory
    pdm run pre-commit-update out+err> /dev/null
  }
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

def get_pre_commit_config_repos [config: string] {
  $config
  | from yaml
  | get repos
}

export def get_pre_commit_config_yaml [config: list<any>] {
  {repos: $config}
  | to yaml
}

export def merge_pre_commit_configs [
  generic_config: string
  environment_config: string
] {
  let generic_config = (get_pre_commit_config_repos $generic_config)
  let environment_config = (get_pre_commit_config_repos $environment_config)

  merge_records_by_key $generic_config $environment_config repo
}

def copy_pre_commit_config [
  settings: record<
    environment: string
    generic_source_directory: string
    generic_build_directory: string
    source_directory: string
    build_directory: string
  >
] {
  let pre_commit_config_filename = ".pre-commit-config.yaml"

  let environment_config_path = (
    $settings.source_directory
    | path join $pre_commit_config_filename
  )

  let generic_config = (
    open --raw (
      $settings.generic_source_directory
      | path join $pre_commit_config_filename
    )
  )

  let build_pre_commit_config = (
    $settings.build_directory
    | path join ".pre-commit-config.yaml"
  )

  update_pre_commit_update generic

  let repos = if ($environment_config_path | path exists) {
    update_pre_commit_update $settings.environment

    let environment_config = (open --raw $environment_config_path)

    merge_pre_commit_configs $generic_config $environment_config
  } else {
    get_pre_commit_config_repos $generic_config
  }

  get_pre_commit_config_yaml $repos
  | save --force $build_pre_commit_config

  print $"Updated ($build_pre_commit_config)"
}

def copy_flake [
  settings: record<
    environment: string
    generic_source_directory: string
    generic_build_directory: string
    source_directory: string
    build_directory: string
  >
] {
  let generic_flake = ($settings.generic_source_directory | path join flake.nix)
  let environment_flake_filename =  $"($settings.environment).nix"

  let environment_flake = (
    [$settings.source_directory nix $environment_flake_filename]
    | path join
  )

  let build_flake = ($settings.build_directory | path join flake.nix)

  cp $generic_flake $build_flake

  print $"Updated ($build_flake)"

  if ($environment_flake | path exists) {
    let nix_directory = ($settings.build_directory | path join nix)

    mkdir $nix_directory

    let build_environment_flake = (
      $nix_directory 
      | path join $environment_flake_filename
    )

    cp $environment_flake $build_environment_flake

    print $"Updated ($build_environment_flake)"
  }
}

def get_source_files [
  settings: record<
    environment: string
    generic_source_directory: string
    generic_build_directory: string
    source_directory: string
    build_directory: string
  >
] {
  get_environment_files $settings
  | filter {|file| ($file | path type) != "dir"}
}

def get_build_files [
  settings: record<
    environment: string
    generic_source_directory: string
    generic_build_directory: string
    source_directory: string
    build_directory: string
  >
] {
  get_environment_files --build $settings
  | filter {|file| ($file | path type) != "dir"}
}

def remove_deleted_files [
  $source_files: list<string>
  $build_files: list<string>
  $environment: string
] {
  let source_files = (
    $source_files
    | str replace "src/" ""
    | str replace $"generic/" $"($environment)/"
  )

  for file in (
    $build_files
    | filter {
        |file|

        if $environment == "dev-scripts" {
          (
            "dev-scripts" 
            | path join $file
          ) not-in $source_files
        } else {
          (
            $file
            | str replace "build/" ""
          ) not-in $source_files
        }
      }
  ) {
    rm $file

    print $"Removed deleted file: ($file)"
  }
}

def force_copy_files [
  settings: record<
    environment: string
    generic_source_directory: string
    generic_build_directory: string
    source_directory: string
    build_directory: string
  >
  skip_dev_flake: bool
] {
  (
    remove_deleted_files 
      (get_source_files $settings) 
      (get_build_files $settings) 
      $settings.environment
  )

  copy_source_files (get_environment_files $settings) $settings
  copy_justfile $settings
  copy_gitignore $settings
  copy_pre_commit_config $settings

  if $settings.environment != "dev-scripts" or not $skip_dev_flake {
    copy_flake $settings
  }
}

def get_filenames_and_modified [files: list<string>] {
  $files
  | each {|file| ls $file}
  | flatten
  | select name modified
}

def get_outdated_files [
  environment: string
  source_files: list<string>
  build_files: list<string>
] {
  $source_files
  | update name {|row| $row.name | str replace "src/" ""}
  | filter {
      |file|

      let build_file_name = if $environment == "dev-scripts" {
        $file.name
        | str replace "dev-scripts/" ""
      } else {
        "build" 
        | path join $file.name
      }

      let build_file_name = if $environment == "dev-scripts" {
        $build_file_name
        | str replace "generic/" ""
      } else {
        $build_file_name
        | str replace "generic/" $"($environment)/"
      }

      if $build_file_name not-in $build_files.name {
        true
      } else {
        let build_file_modified = (
          $build_files          
          | filter {|file| $file.name == $build_file_name}
          | first
          | get modified
        )

        $file.modified > $build_file_modified
      }
    }
  | each {|file| [src $file.name] | path join}
}

def copy_outdated_files [
  settings: record<
    environment: string
    generic_source_directory: string
    generic_build_directory: string
    source_directory: string
    build_directory: string
  >
] {
  let source_files = (get_source_files $settings)
  let build_files = (get_build_files $settings)
  let environment = $settings.environment

  remove_deleted_files $source_files $build_files $environment

  let outdated_files = (
    get_outdated_files 
      $environment
      (get_filenames_and_modified $source_files)
      (get_filenames_and_modified $build_files)
  )

  mut source_files = []

  for file in $outdated_files {
    let basename = ($file | path basename)
    let extension = ($basename | path parse | get extension)

    if $basename == ".gitignore" {
      copy_gitignore $settings
    } else if $basename == ".pre-commit-config.yaml" {
      copy_pre_commit_config $settings
    } else if $extension == "nix" {
      copy_flake $settings
    } else if $basename == "Justfile" or $extension == "just" {
      copy_justfile $settings
    } else {
      $source_files = ($source_files | append $file)      
    }
  }

  copy_source_files $source_files $settings
}

# Build dev environments
export def main [
  ...environments: string
  --force # Build environments even if up-to-date
  --skip-dev-flake # Skip building the dev flake.nix to avoid triggering direnv
] {
  let environments = if ($environments | is-empty) {
    eza src
    | lines
  } else {
    $environments
  }

  $environments
  | par-each {
      |environment|

      print $"Building ($environment)..."

      let settings = (get_settings $environment)

      if $force {
        force_copy_files $settings $skip_dev_flake
      } else {
        copy_outdated_files $settings
      }
    }
  | null
}
