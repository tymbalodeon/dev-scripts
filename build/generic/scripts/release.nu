#!/usr/bin/env nu

use ./check.nu

# Create a new release
export def main [
    --preview # Preview new additions to the CHANGELOG without modifyiing anything
] {
  if not $preview {
    if not ((git branch --show-current) == "trunk") {
      return "Can only release from the trunk branch."
    }

    if not (git status --short | is-empty) {
      return "Please commit all changes before releasing."
    }

    check
  }

  if $preview {
      return (git-cliff --bump --unreleased)
  }

  # git-cliff --unreleased --tag $new_version --prepend CHANGELOG.md
  # git add CHANGELOG.md
  # git commit --message $"chore\(release\): bump version to ($new_version)"
  # git tag $"v($new_version)"
  # git push --follow-tags
}
