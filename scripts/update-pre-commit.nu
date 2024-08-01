#!/usr/bin/env nu

export def main [] {
  for environment in (ls src) {
    let environment = $environment.name

    cd $environment

    if (".pre-commit-config.yaml" | path exists) {
      (
        print
          --no-newline
          $"Updating \"($environment | path basename)\" pre-commit hooks..."
      )

      do --ignore-errors {
        pdm run pre-commit-update
      }
    }

    cd -
  }
}
