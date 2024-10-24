#!/usr/bin/env nu

use ../environment.nu merge_gitignores
use ../environment.nu merge_justfiles
use ../environment.nu merge_pre_commit_configs

def get_environment_files [] {
  fd --hidden --ignore --exclude .git "" src/generic
  | lines
  | filter {
      |file|

      let path = ($file | path parse)

      (
        ($file | path type) == "file"
        and "tests" not-in $path.parent
        and $path.extension != "lock"
      )
    }
}

def get_build_path [path: string] {
  $path
  | str replace --regex "src/[a-zA-Z-_]+/" ""
}

def get_environment_directories [environment_files: list<string>] {
  $environment_files
  | path parse
  | get parent
  | uniq
  | str replace "src/generic" ""
  | filter {|directory| $directory | is-not-empty}
  | str replace "/" ""

}

def copy_files [environment_files: list<string>] {
  for directory in (get_environment_directories $environment_files) {
    mkdir $directory
  }

  let environment_files = (
    $environment_files
    | filter {
        |file|

        ($file | path basename) not-in [
          .gitignore
          .pre-commit-config.yaml
          Justfile
        ] and ($file | path parse | get extension) != "just"
      }
  )

  for file in $environment_files {
    let build_path = (get_build_path $file)

    cp $file $build_path

    print $"Updated ($build_path)"
  }
}

def copy_justfile [] {
  (
    merge_justfiles
      generic
      Justfile
      src/generic/Justfile
  ) | save --force Justfile

  print $"Updated Justfile"
}

def copy_gitignore [] {
  (
    merge_gitignores
      (open .gitignore)
      (open src/generic/.gitignore)
  ) | append "\n"
  | str join
  | save --force .gitignore

  print $"Updated .gitignore"
}

def copy_pre_commit_config [] {
  (
    merge_pre_commit_configs
      (open .pre-commit-config.yaml)
      (open src/generic/.pre-commit-config.yaml)
  ) | save --force .pre-commit-config.yaml

  yamlfmt .pre-commit-config.yaml

  print $"Updated .pre-commit-config.yaml"
}

def force_copy_files [] {
  copy_files (get_environment_files)
  copy_justfile
  copy_gitignore
  copy_pre_commit_config
}

def get_modified [file: string] {
  try {
    ls $file
    | first
    | get modified
  }
}

def get_files_and_modified [] {
  get_environment_files
  | wrap environment
  | insert local {
      |$file|

      $file.environment | str replace "src/generic/" ""
    }
  | insert environment_modified {
      |row|

      get_modified $row.environment
    }
  | insert local_modified {
      |row|

      get_modified $row.local
  }
}

export def get_outdated_files [files: list] {
  $files
  | filter {
      |file|

      ($file.local_modified == null) or (
        $file.environment_modified > $file.local_modified
      )
    }
  | get environment
}

def copy_outdated_files [] {
  let outdated_files = (get_outdated_files (get_files_and_modified))

  mut environment_files = []

  for file in $outdated_files {
    let basename = ($file | path basename)
    let extension = ($basename | path parse | get extension)

    if $basename == ".gitignore" {
      copy_gitignore
    } else if $basename == ".pre-commit-config.yaml" {
      copy_pre_commit_config
    } else if $basename == "Justfile" {
      copy_justfile
    } else {
      $environment_files = ($environment_files | append $file)
    }
  }

  copy_files $environment_files
}

# Build dev environment
def main [
  --force # Build environment even if up-to-date
] {
  if $force {
    force_copy_files
  } else {
    copy_outdated_files
  }
}
