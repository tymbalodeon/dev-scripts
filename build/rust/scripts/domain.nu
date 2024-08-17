#!/usr/bin/env nu

def main [] {
  let origin = (git remote get-url origin)

  let values = (
    if ($origin | str starts-with "git@") {
      $origin
      | parse "git@{domain}.com:{user}/{repo}.git"
    } else if ($origin | str starts-with "http") {
      $origin
      | str replace --regex "https?://" ""
      | parse "https://{domain}.com/{user}/{repo}.git"
    } else if ($origin | str starts-with "ssh://") {
      $origin
      | parse "ssh://git@{domain}.com/{user}/{repo}.git"
    } else {
      print --stderr $"Unable to parse remote origin: \"($origin)\""

      exit 1
    }
  )

  return (
    $values
    | first
    | get domain
  )
}
