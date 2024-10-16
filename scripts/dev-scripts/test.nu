#!/usr/bin/env nu

# Run tests
def main [
  environment?: string # Run $environment tests only
  file?: string # Run only $file test for $environment
] {
  let tests = try {
    let files = if ($environment | is-empty) {
      "scripts/dev-scripts/tests/test_*.nu"
    } else if ($file | is-empty) {
      $"src/($environment)/**/tests/test_*.nu"
    } else {
      let file = if ($file | path parse | get extension) == "nu" {
        $file
      } else {
        $"($file).nu"
      }

      let file = if (($file | path basename) | str starts-with "test_") {
        $file
      } else {
        $"test_($file)"
      }

      $"src/($environment)/**/tests/($file)"
    }

    ls ($files | into glob)
    | get name
  } catch {
    return
  }

  for test in $tests {
    # print $test
    print --no-newline $"($test)..."

    try {
      nu $test

      print $"(ansi green_bold)OK(ansi reset)"
    }
  }
}
