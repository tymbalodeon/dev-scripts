#!/usr/bin/env nu

# Run tests
def main [] {
  let tests = try {
    ls src/**/tests/*.nu
    | get name
  } catch {
    []
  }

  for test in $tests {
    nu $test
  }
}
