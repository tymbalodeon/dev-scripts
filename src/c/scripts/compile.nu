#!/usr/bin/env nu

def get_binary_file_name [file: string] {
  $file
  | str replace ".c" ""
  | str replace "src" "build"
}

def get_modified [file: string] {
  ls $file
  | get modified
}

def is_outdated [source_file: string target_file?: string] {
  let target_file = if ($target_file | is-empty) {
    get_binary_file_name $source_file
  } else {
    $target_file
  }

  not ($target_file | path exists) or (
    (get_modified $source_file) >
    (get_modified $target_file)
  )
}

def compile [file: string force: bool] {
  if $force or (is_outdated $file) {
    print $"Compiling ($file)..."
    cc $file -o (get_binary_file_name $file)
  }
}

export def main [
  file?: string # The file to compile
  --force # Re-compile even if up-to-date
] {
  mkdir build

  if ($file | is-empty) {
    for file in (ls src/*.c | get name) {
      compile $file $force
    }
  } else {
    let files = (
      fd --extension c $file
      | lines
    )

    let file = if ($files | is-not-empty) {
      $files | first
    }

    compile $file $force
  }
}
