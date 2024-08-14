#!/usr/bin/env nu

use ./compile.nu

def lox [file?: string] {
  if ($file | is-empty) {
    java com.craftinginterpreters.lox.Lox
  } else {
    java com.craftinginterpreters.lox.Lox $file
  }
}

def main [
  file?: string # The file to interpret
  --example # Run the example file
] {
  compile

  if $example {
    lox example.lox
  } else {
    lox $file
  }
}
