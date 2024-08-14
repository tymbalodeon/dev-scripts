#!/usr/bin/env nu

def get_diff [type: string local_file: record file?: string accept = false] {
  if not (
    $local_file.name in (
      fd --exclude .git --hidden
      | lines
      | each {|file| $file | str replace --regex "/$" ""}
    )
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
      let official_file = (
        http get
          --raw
          $"($base_url)/($type)/($local_file.name)"
      )

      let diff = (
        bash -c
          $"delta \\
            --paging never \\
            ($local_file.name) \\
            <\(printf '(echo $official_file)'\)"
        | complete
      )

      if $diff.exit_code != 1 {
        return
      }

      let diff = $diff.stdout

      if $accept {
        $official_file
        | save --force $local_file.name
      }

      return $diff
    } catch {
      return
    }
  }

  for nested_file in (ls --all $local_file.name) {
    get_diff $type $nested_file $file
  }
}

def main [type?: string --file: string --accept] {
  let type = if ($type | is-empty) {
    "main"
  } else {
    $type
  }

  for local_file in (ls --all) {
    print (get_diff $type $local_file $file $accept)
  }
}
