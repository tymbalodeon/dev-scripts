#!/usr/bin/env nu

use ./compile.nu

def main [
  file?: string # The file to interpret
  --example # Run the example file
] {
  compile
  java $file
}
