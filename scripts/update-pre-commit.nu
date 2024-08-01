#!/usr/bin/env nu

export def main [] {
  let environments = (ls build | enumerate)

  for item in $environments {
    let environment = $item.item.name

    print $"Updating ($environment)..."

    cd $environment

    do --ignore-errors {
      just check pre-commit-update
    }

    if $item.index < (($environments | length) - 1) {
      print ""
    }

    cd -
  }
}
