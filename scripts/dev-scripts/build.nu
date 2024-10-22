#!/usr/bin/env nu

use ../environment.nu merge_gitignores
use ../environment.nu merge_justfiles
use ../environment.nu merge_pre_commit_configs

def get_environment_files [] {
  fd --hidden --ignore --exclude .git "" src/generic
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
  | filter {
      |file|

      for item in [
        CHANGELOG.md
        flake.lock
        pdm.lock
      ] {
        if ($item | str ends-with "/") and (
            $item in ($file | path parse | get parent)
        ) or ($item in $file) {
          return false
        }
      }

      true
    }
  | filter {|file| "/tests" not-in $file}
}

def get_build_path [path: string] {
  "./"
  | path join (
    $path
    | str replace --regex "src/[a-zA-Z-_]+/" ""
  )
}

def get_source_directories [source_files: list<string>] {
  $source_files
  | path dirname
  | uniq
  | filter {|directory| $directory != "generic"}
  | each {|directory| get_build_path $directory}
  | uniq
}

def copy_files [source_files: list<string>] {
  let directories = (get_source_directories $source_files)

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
  ) | save --force .gitignore

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

def force_copy_files [skip_dev_flake: bool] {
  # TODO determine if this still makes sense for new system
  # (
  #   remove_deleted_files
  #     dev-scripts
  #     (get_source_files $settings)
  #     (get_build_files $settings)
  # )

  copy_files (get_environment_files)
  copy_justfile
  copy_gitignore 
  copy_pre_commit_config
}

def get_modified [file: string] {
  ls $file
  | first
  | get modified
}

def get_outdated_files [] {
  get_environment_files
  | wrap environment
  | insert local {
      |$file| 

      $file.environment | str replace "src/generic/" ""
    }
  | filter {
      |file|

      (get_modified $file.environment) > (get_modified $file.local)
  }
}

def copy_outdated_files [] {
  let outdated_files = (get_outdated_files).environment

  mut source_files = []

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
      $source_files = ($source_files | append $file)
    }
  }

  copy_files $source_files
}

# Build dev environment
def main [
  --force # Build environment even if up-to-date
  --skip-dev-flake # Skip building the dev flake.nix to avoid triggering direnv
] {
  if $force {
    force_copy_files $skip_dev_flake
  } else {
    copy_outdated_files
  }
}
