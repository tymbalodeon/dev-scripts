#!/usr/bin/env nu

use ./hosts.nu 
use ./hosts.nu get_available_host_names
use ./hosts.nu get_available_hosts
use ./hosts.nu get_built_host_name
use ./hosts.nu get_darwin_hosts
use ./hosts.nu get_nixos_hosts
use ./hosts.nu get_systems
use ./hosts.nu is_nixos

def raise_configuration_error [configuration: string] {
  print $"Unrecognized host or system name: `($configuration)`\n"
  print "Please specify a valid host or system name:"
  print (hosts)

  exit 1
  
}

def validate_configuration [configuration: string] {
  let configuration = ($configuration | str downcase)

  if not ($configuration in (get_available_host_names)) {
    raise_configuration_error $configuration
  }

  return $configuration
}

def validate_source_and_target [source?: string target?: string] {
  let validated_source = if (
    ($source | is-empty) or ($target | is-empty)
  ) {
    get_built_host_name
  } else {
    validate_configuration $source
  }

  let validated_target = if ($target | is-empty) {
    if ($source | is-empty) {
      if (is_nixos) {
        "darwin"
      } else {
        "nixos"
      }
    } else {
      validate_configuration $source
    }
  } else {
    validate_configuration $target
  }

  return (
    {
      source: $validated_source
      target: $validated_target
    }
  )
}

def get_shared_configuration_files [configuration?: string] {
  if ($configuration | is-empty) {
    return (
      fd 
        --exclude ".git"
        --exclude ".gitignore"
        --exclude ".pre-commit-config.yaml"
        --exclude ".stylelintrc.json"
        --exclude "Justfile"
        --exclude "README.md"
        --exclude "darwin"
        --exclude "flake.lock"
        --exclude "nixos"
        --exclude "scripts"
        --hidden
        --type "file"
        ""
    )
  } else {
    let excludes = {
      benrosen: ["nixos" "work"]
      bumbirich: ["darwin" "ruzia"]
      darwin: ["benrosen" "nixos" "work"]
      nixos: ["bumbirich" "darwin" "ruzia"]
      ruzia: ["bumbirich" "darwin"]
      work: ["benrosen" "nixos"]
    } | get $configuration

    return (
      (
        fd 
          --exclude ".git"
          --exclude ".gitignore"
          --exclude ".pre-commit-config.yaml"
          --exclude ".stylelintrc.json"
          --exclude "Justfile"
          --exclude "README.md"
          --exclude "flake.lock"
          --exclude "scripts"
          --hidden
          --type "file"
          ""
      )
      | lines
      | filter {
          |line|

          mut keep = true

          for exclude in $excludes {
            if $exclude in $line {
              $keep = false
              break
            }            
          }

          $keep
      }
      | to text
    )
  }
}

def format_files [
  files: string 
  unique_files: bool
  configuration?: string 
] {
  let include_shared = not $unique_files
  let darwin_hosts = (get_darwin_hosts)

  let files = (
    $files 
    | lines
    | each {
        |line| 
        
        let directories = (
          $line 
          | path split 
        )

        let $base = ($directories | first)

        let file_configuration = if (
          $directories | get 1
        ) in $darwin_hosts {
          $base | path join ($directories | get 1)
        } else {
          $base
        }

        (
          $line 
          | str replace $"($file_configuration)/" ""
        ) + $" [($file_configuration)/]"
    }
  )

  let files = if $include_shared {
    (get_shared_configuration_files | lines) ++ $files
  } else {
    $files
  }

  let darwin_hosts = (get_darwin_hosts --with-system)
  let nixos_hosts = (get_nixos_hosts --with-system)
  let hosts = (get_available_hosts --list)

  return (
    $files
    | sort
    | each {
        |line| 

        if "[" in $line {
          let file_configuration = if "bumbirich" in $line {
            "bumbirich"
          } else if "ruzia" in $line {
            "ruzia"
          } else (
            $line
            | rg '\[.+\]' --only-matching
            | str replace "[" ""
            | str replace "]" ""
            | split row "/"
            | filter {|directory| not ($directory | is-empty)}
            | last
          )

          let color = if $include_shared or $unique_files {
            let $configuration = if ($configuration | is-empty) {
              ""
            } else {
              $configuration
            }

            let is_darwin_configuration = ($configuration in $darwin_hosts)
            let is_nixos_configuration = ($configuration in $nixos_hosts)
            let is_host_configuration = ($configuration in $hosts)

            let host_color = if $is_host_configuration {
              "n"
            } else {
              "ub"
            }

            let darwin_color = if $is_darwin_configuration {
              "n"
            } else {
              "pb"
            }

            let nixos_color = if $is_nixos_configuration {
              "n"
            } else {
              "ub"
            }

            let darwin_host_color = if $is_darwin_configuration {
              $host_color
            } else {
              "yb"
            }

            let nixos_host_color = if $is_nixos_configuration {
              $host_color
            } else {
              "cb"
            }

            {
              "benrosen": $darwin_host_color
              "bumbirich": $nixos_host_color
              "darwin": $darwin_color
              "nixos": $nixos_color
              "ruzia": $nixos_host_color
              "work": $darwin_host_color
            } | get $file_configuration
          } else {
            mut color = "n"

            for host in $hosts {
              if $host in $line {
                $color = "cb"

                break
              }
            }

            $color
          }

          $"(ansi $color)($line)(ansi reset)"
        } else { 
          $line 
        }
    }
    | to text
  )
}

def split_paths [paths: list<string>] {
  let systems = (get_systems)

  return (
    $paths
    | each {|file| $file | path parse}
    | insert system {
        |row| 
        
        let dirname = (
          $row.parent 
          | path dirname
        )

        if $dirname in $systems {
          $dirname
        } else {
          null
        }
      }
    | update parent {|row| $row.parent | path basename}
  )
}

def get_excluded_paths_pattern [name: string] {
  return (
    {
      benrosen: "work"      
      bumbirich: "ruzia"      
      ruzia: "bumbirich"      
      work: "benrosen"      
    } 
    | get $name
  )
  
}

def get_host_files [host_directory: string --with-shared] {
  let nested_path = ("/" in $host_directory)

  let system_directory = if $nested_path {
    $host_directory | path dirname
  } else {
    $host_directory
  }

  let host_name = if $nested_path {
    $host_directory | path basename
  } else {
    $host_directory
  }

  let files = (
    if $nested_path {
      let exclude_pattern = (get_excluded_paths_pattern $host_name)

      (
        fd 
          --exclude $"*($exclude_pattern)*" 
          --hidden 
          --type "file" 
          "" 
          $system_directory
      )
    } else {
      (
        fd 
          --hidden 
          --type "file" 
          "" 
          $system_directory
      )
    }
    | lines
  )

  let host_files = (split_paths $files)

  return (
    if $with_shared {
      $host_files ++ (
        split_paths (
          get_shared_configuration_files 
          | lines
        )
      )
    } else {
      $host_files  
    }
  )
}

def get_file_and_system [row: record] {
  return {
    file: (
      ($row | reject system) 
      | path join
    )

    system: $row.system
  }
}

def get_full_path [file: record] {
  let path = ($file | reject system | path join)

  return (
    if ($file.system | is-empty) {
      $path
    } else {
      $file.system | path join $path
    }
  )
}

def get_common_files [
  target: string 
  source_files: list
  target_files: list
] {
  let systems = (get_systems) 

  let available_hosts = (
    (get_available_host_names) 
    | append ""
  )

  mut $common_files = {
    source: []
    target: []
  }

  for source_file in $source_files {
    let matching_files = (
      $target_files 
      | filter {
          |target_file|

          (
            $target_file.stem == $source_file.stem 
            and (
              $target_file.parent == $source_file.parent
              or $target_file.parent in $available_hosts
            )
          )
        }
    )

    $common_files.target = (
      $common_files.target
      | append $matching_files
    )

    if not ($matching_files | is-empty) {
      $common_files.source = (
        $common_files.source
        | append $source_file
      )
    }
  }

  $common_files.source = (
    $common_files.source
    | each {|file| (get_full_path $file)}
  )

  $common_files.target = (
    $common_files.target
    | each {|file| (get_full_path $file)}
  )

  return $common_files
}

def get_configuration_directory [configuration: string] {
  if $configuration in (get_darwin_hosts) {
    return $"darwin/($configuration)"
  } else if $configuration in (get_nixos_hosts) {
    return "nixos"
  } else {
    return $configuration
  }
}

def list_files [unique_files: bool configuration?: string] {
  let configurations = if ($configuration | is-empty) {
    get_available_host_names
  } else {
    [$configuration]
  }

  let systems = (get_systems)
  let darwin_hosts = (get_darwin_hosts)
  let nixos_hosts = (get_nixos_hosts)

  let configuration_files = (
    $configurations 
    | each {
        |configuration|

        if ($configuration in $systems) {
          fd --hidden --type file "" $configuration
          | lines
        } else {
          let system_directory = if $configuration in $darwin_hosts {
            "darwin"
          } else if $configuration in $nixos_hosts {
            "nixos"
          } else {
            raise_configuration_error $configuration
          }

          let exclude_pattern = (get_excluded_paths_pattern $configuration)
    
          (
            fd 
              --exclude $"*($exclude_pattern)*" 
              --hidden 
              --type file 
              "" 
              $system_directory
          )
          | lines
        }
    }
  )
  | flatten
  | uniq
  | to text

  return (format_files $configuration_files $unique_files $configuration)
}

def get_matching_files [files: string file: string] {
  return (
    $files 
    | rg $file
    | lines
    | each {
        |line|

        let parent = (
          $line 
          | split row " "
          | last
          | str replace "[" ""
          | str replace "]" ""
        )

        let file = (
          $line 
          | split row " "
          | first
        )

        $"($parent)($file)" 
        | ansi strip
    }
  )
}

def delta [source: string target: string side_by_side: bool] {
  do --ignore-errors {
    if $side_by_side {
      ^delta --paging never --side-by-side $source $target
    } else {
      ^delta --paging never $source $target
    }
  }
}

# View the diff between configurations
export def main [
  source?: string # Host or system name
  target?: string # Host or system to compare to
  --file: string # View the diff for a specific file
  --files # View files relevant to a host or system configuration
  --shared-files # View only files shared across all configurations
  --side-by-side # View the diff in side-by-side layout
  --unique-files # View only files unique to a host or system configuration
] {
  if ($source | is-empty) {
    if $files or $unique_files {
      return (list_files $unique_files)
    }

    if $shared_files {
      return (get_shared_configuration_files)
    }
  }

  let validated_args = (validate_source_and_target $source $target)
  let source = ($validated_args | get source)
  let target = ($validated_args | get target)

  if not ($file | is-empty) {
    let target_files = (list_files true $target)
    let source_files = (list_files true $source)
    let matching_source_files = (get_matching_files $source_files $file)
    let matching_target_files = (get_matching_files $target_files $file)

    print $matching_source_files
    print $matching_target_files

    for source_file in $matching_source_files {
      for target_file in $matching_target_files {
        if $target_file in $matching_source_files {
          continue
        }

        delta $source_file $target_file $side_by_side
      }
    }

    return
  }

  if $files or $unique_files {
    return (list_files $unique_files $target)
  }

  if $shared_files {
    return (get_shared_configuration_files $target)
  }

  let source_directory = (get_configuration_directory $source)
  let target_directory = (get_configuration_directory $target)
  let source_files = (get_host_files $source_directory --with-shared)
  let target_files = (get_host_files $target_directory)

  let common_files = (
    get_common_files 
      $target
      $source_files 
      $target_files
  )

  let source_files = ($common_files | get source)
  let target_files = ($common_files | get target)

  for files in ($source_files | zip $target_files) {
    let source = ($files | get 0)
    let target = ($files | get 1)

    delta $source $target $side_by_side
  }
}
