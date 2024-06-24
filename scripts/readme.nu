#!/usr/bin/env nu

def make_command_comment [
  command: string
  --end
  --start
] {
  let type = if $end {
    "end"
  } else {
    "start"
  }

  return $"<!-- `($command)` ($type) -->"
}

def make_command_regex [start end] {
  return $"($start)\(.|\\s\)*($end)"
}

def make_command_output [
  start: string
  output: string
  end: string
] {
  return $"($start)\n\n($output)\n\n($end)"
}

# Update README command output
export def main [] {
  let just_start = (make_command_comment "just")
  let just_end = (make_command_comment "just" --end)

  let just_output = (
    $"```nushell\n(
        just | ansi strip
      )\n```"
  )

  (
    open README.md
    | str replace
      --regex
      (make_command_regex $just_start $just_end)
      (make_command_output $just_start $just_output $just_end)
    | save --force README.md
  )
}
