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

  let layout = if $open {
    $layout
  } else {
    $layout
    | lines
    | filter {
        |line|

        not ("--open" in $line)
      }
    | to text
  }

  $layout | save --force $layout_file

  zellij --layout $layout_file
}
