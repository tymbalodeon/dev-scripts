#!/usr/bin/env nu

export def main [
  type: string # Conventional commit type [possible values: build, ci, refactor, revert, style, fix, test, feat, chore, docs, perf]
  message: string # Commit description
  scope?: string # Conventional commit scope
  --add # Add files to the commit (similar to git add .)
] {
  if $add {
    if ($scope | is-empty) {
      cog commit --add $type $message
    } else {
      cog commit --add $type $message $scope
    }
  } else {
    if ($scope | is-empty) {
      cog commit $type $message
    } else {
      cog commit $type $message $scope
    }
  }
}
