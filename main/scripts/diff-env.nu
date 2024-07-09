#!/usr/bin/env nu

def get_diff [type: string local_file: record file?: string] {
  if not (
    $local_file.name in (exa --git-ignore --all | lines | append ".git")
  ) {
    return
  }

  if $local_file.type == "file" {
    if not (
      $file | is-empty
    ) and not (
      ($file | str downcase) in ($local_file.name | str downcase)
    ) {
      return
    }

    let base_url = "https://raw.githubusercontent.com/tymbalodeon/dev-scripts/trunk"

    try {
      let official_local_file = (
        http get
          --raw
          $"($base_url)/($type)/($local_file.name)"
      )

      return (
        bash -c 
          $"delta --paging never <\(echo '(echo $official_local_file)'\) ($local_file.name)"
      )
    } catch {
      return
    }
  }

  for nested_file in (ls --all $local_file.name) {
    return (get_diff $type $nested_file $file)
  }
}

export def main [type?: string --file: string] {
  let type = if ($type | is-empty) {
    "main"
  } else {
    $type
  }

  for local_file in (ls --all) {
    print (get_diff $type $local_file $file)
  }
}
