#!/usr/bin/env nu

def get_class_file [file: string] {
  return (
    $file
    | path parse
    | update extension class
    | path join
  )
}

def get_modified [file: string] {
  return (
    ls $file
    | get modified
  )
}

def is_outdated [source_file: string target_file?: string] {
  let target_file = if ($target_file | is-empty) {
    get_class_file $source_file
  } else {
    $target_file
  }

  return (
    not ($target_file | path exists)
    or (
      (get_modified $source_file) >
      (get_modified $target_file)
    )
  )
}

def compile [file: string] {
  if (is_outdated $file) {
    print $"Compiling ($file)"
    javac $file
  }
}

def generate_ast [] {
  let generator_file = "com/craftinginterpreters/tool/GenerateAst.java"
  let generator_class_file = (get_class_file $generator_file)

  compile $generator_file

  for file in ["Expr" "Stmt"] {
    if (
      is_outdated
        $generator_file
        $"com/craftinginterpreters/lox/($file).java"
    ) {
      print "Generating AST..."

      java com.craftinginterpreters.tool.GenerateAst com/craftinginterpreters/lox

      break
    }
  }
}

export def main [
  file?: string # The file to compile
] {
  if ($file | is-empty) {
    generate_ast

    for file in (ls com/craftinginterpreters/lox/*.java) {
      compile $file.name
    }
  } else {
    print $"Compiling ($file)..."

    compile $file
  }
}
