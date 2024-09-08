#!/usr/bin/env nu

use ./compile.nu

def main [
  file: string # The file to interpret
] {
  let source_file = $"src/($file).c"

  if not ($source_file | path exists) {
    print $"($source_file) does not exist"

    exit 1
  }

  compile $file

  ^$"./build/($file)"
}
