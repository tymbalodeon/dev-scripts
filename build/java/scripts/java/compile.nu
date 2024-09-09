#!/usr/bin/env nu

def get_class_file [file: string] {
  $file
  | path parse
  | update extension class
  | path join
}

def get_modified [file: string] {
  ls $file
  | get modified
}

def is_outdated [source_file: string target_file?: string] {
  let target_file = if ($target_file | is-empty) {
    get_class_file $source_file
  } else {
    $target_file
  }

  not ($target_file | path exists) or (
    (get_modified $source_file) >
    (get_modified $target_file)
  )
}

def compile [file: string] {
  if (is_outdated $file) {
    print $"Compiling ($file)"

    javac $file
  }
}

def main [
  file?: string # The file to compile
] {
  if ($file | is-empty) {
    for file in (ls src/*.java) {
      compile $file.name
    }
  } else {
    print $"Compiling ($file)..."

    compile $file
  }
}
