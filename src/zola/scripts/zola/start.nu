#!/usr/bin/env nu

def main [--open] {
  let project_url = (
    open config.toml
    | get base_url
    | str replace --regex "http(s?)://" ""
    | str replace --regex "/$" ""
  )

  let layout_file = (mktemp --tmpdir $"($project_url)-XXX.kdl")

  open zellij-layout.kdl
  | str replace "[name]" $project_url
  | save --force $layout_file

  if $open {
    start http://127.0.0.1:1111
  }

  zellij --layout $layout_file --session $project_url
  rm --force $layout_file
  zellij delete-session $project_url
}
