#!/usr/bin/env nu

def get_diff [type: string file: record] {
  if $file.name in (open .gitignore | lines | append ".git") {
    return
  }

  if $file.type == "file" {
    try {
      let official_file = (
        http get
          --raw
          $"https://raw.githubusercontent.com/tymbalodeon/dev-scripts/trunk/($type)/($file.name)"
      )

      return (
        bash -c 
          $"delta --paging never <\(echo '(echo $official_file)'\) ($file.name)"
      )
    } catch {
      return
    }
  }

  for nested_file in (ls --all $file.name) {
    return (get_diff $type $nested_file)
  }
}

export def main [type?: string] {
  let type = if ($type | is-empty) {
    "main"
  } else {
    $type
  }

  for file in (ls --all) {
    print (get_diff $type $file)
  }
}
