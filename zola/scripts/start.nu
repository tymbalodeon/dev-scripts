#!/usr/bin/env nu

export def main [--open] {
  let project_url = (
    open config.toml 
    | get base_url
    | str replace --regex "http(s?)://" ""
    | str replace --regex "/$" ""
  )

  for file in (ls $env.TMPDIR | where name =~ $project_url) {
    rm -rf $file.name
  }

  let layout_file = (mktemp --tmpdir $"($project_url).XXX")

  open zellij-layout.kdl
  | str replace "[name]" $project_url
  | save --force $layout_file

  if $open {
    start http://127.0.0.1:1111
  }

  zellij --layout $layout_file
}
