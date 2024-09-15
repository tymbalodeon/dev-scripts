use std assert

use ../domain.nu parse_git_origin
use ./print_test.nu

let origins = [
  "git@github.com:tymbalodeon/dev-scripts.git"
  "http://github.com:tymbalodeon/dev-scripts.git"
  "https://github.com:tymbalodeon/dev-scripts.git"
  "ssh://git@github.com/tymbalodeon/dev-scripts.git"
]

let expected_domain = "github"
let expected_owner = "tymbalodeon"
let expected_repo = "dev-scripts"

for origin in $origins {
  let actual_origin = (parse_git_origin $origin)

  assert equal ($actual_origin | get domain) $expected_domain
  assert equal ($actual_origin | get owner) $expected_owner
  assert equal ($actual_origin | get repo) $expected_repo

  let type = if ($origin | str starts-with "git") {
    "git"
  } else if ($origin | str starts-with "ssh") {
    "ssh"
  } else if ($origin | str starts-with "https") {
    "https"
  } else if ($origin | str starts-with "http") {
    "http"
  }

  print_test $"Parse \"($type)\" git origin"
}

let invalid_origin = "github.com/tymbalodeon/dev-scripts"
let actual_invalid_origin = (parse_git_origin --quiet $invalid_origin)

assert equal ($actual_invalid_origin | get domain) null
assert equal ($actual_invalid_origin | get owner) null
assert equal ($actual_invalid_origin | get repo) null

print_test "Parse invalid git origin"
