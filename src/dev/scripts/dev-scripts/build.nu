#!/usr/bin/env nu

def get_source_directory [environment: string] {
  $"../src/($environment)"
}

def get_build_directory [environment: string] {
  if $environment == "dev" {
    "../"
  } else {
    $"../build/($environment)"
  }
}

def get_build_path [environment: string path: string] {
  get_build_directory $environment
  | path join (
    $path
    | str replace --regex ".+/src/[a-zA-Z]+/" ""
  )
}

def get_justfile [base_directory: string] {
  $base_directory | path join Justfile
}

def get_recipes [justfile: string] {
  (
    just
      --justfile $justfile
      --summary
    | split row " "
  )
}

def create_environment_recipe [environment: string recipe: string] {
  let documentation = $"# Alias for `($environment) ($recipe)`"
  let declaration = $"@($recipe) *args:"
  let content = $"    just ($environment) ($recipe) {{ args }}"

  [$documentation $declaration $content]
  | str join "\n"
}

def get_gitignore_source [environment: string] {
  let file = $"(get_source_directory $environment)/.gitignore"

  if ($file | path exists) {
    open $file
    | lines
  } else {
    []
  }
}

def merge_gitignore [environment: string] {
}

def get_target_value [source_value: record target: list column: string] {
  let target_value = (
    $target
    | filter {
        |target_value|

        ($target_value | get $column) == ($source_value | get $column)
      }
  )

  if ($target_value | is-empty) {
    $target_value
  } else {
    $target_value
    | first
  }
}

def merge_records_by_key [a: list b: list key: string] {
  mut records = []

  for b_record in $b {
    if ($b_record | get $key) in ($a | get $key) {
      let a_record = (
        $a
        | filter {
            |a_record|

            ($a_record | get $key) == ($b_record | get $key)
          }
        | first
      )

      if $key == "repo" {
        let a_hooks = $a_record.hooks
        let b_hooks = $b_record.hooks
        let hooks = (merge_records_by_key $a_hooks $b_hooks "id")

        $records = (
          $records
          | append ($b_record | update hooks $hooks)
        )
      } else {
        $records = (
          $records
          | append ($a_record | merge $b_record)
        )
      }
    } else {
      $records = (
        $records
        | append $b_record
      )
    }
  }

  for a_record in $a {
    if not (($a_record | get $key) in ($records | get $key)) {
      $records = ($records | append $a_record)
    }
  }

  $records
}

def update_pre_commit_update [environment: string] {
  let directory = (get_source_directory $environment)

  try {
    cd $directory
    pdm run pre-commit-update out+err> /dev/null
  }
}

def get_flake [environment: string] {
  (get_source_directory $environment)
  | path join flake.nix
}

def get_flake_inputs [environment: string] {
  let flake = (get_flake $environment)

  (
    nix eval
      --apply 'builtins.getAttr "inputs"'
      --file $flake
      --json
    | from json
  )
}

def get_generated_flake [environment: string] {
  if $environment == "dev" {
    mktemp --tmpdir flake-XXX.nix
  } else {
    get_build_directory $environment
    | path join flake.nix
  }
}

def merge_flake_inputs [environment: string generated_flake: string] {
  mut merged_inputs = {}

  for item in ["generic" $environment] {
    let inputs = (get_flake_inputs $item)

    $merged_inputs = ($merged_inputs | merge $inputs)
  }

  let merged_inputs = {inputs: $merged_inputs}

  let inputs = (
    nix eval
      --apply builtins.fromJSON
      --expr (
        $merged_inputs
        | to json
        | to json
      )
    | alejandra --quiet --quiet
    | lines
    | drop nth 0
    | drop
  )

  "\{\n"
  | append $inputs
  | append "\n"
  | append (
    open $generated_flake
    | lines
    | drop nth 0
  ) | save --force $generated_flake

  alejandra --quiet --quiet $generated_flake

  if $environment == "dev" {
    cp $generated_flake ../flake.nix
    rm $generated_flake
  }
}

def get_flake_packages [environment: string] {
  open (get_flake $environment)
  | rg --multiline "packages = with pkgs; \\[(\n|.)+\\];"
  | lines
  | drop nth 0
  | drop
  | str trim
}

def get_flake_shell_hook [environment: string] {
  open (get_flake $environment)
  | rg --multiline "shellHook = ''(\n|.)+'';"
  | lines
  | drop nth 0
  | drop
  | str trim
}

def merge_flake_outputs [environment: string generated_flake: string] {
  let packages = if $environment == "generic" {
     get_flake_packages "generic"
  } else {
    get_flake_packages "generic"
    | append (
        get_flake_packages $environment
      )
    | uniq
    | sort
  }

  let shell_hook = (
    if $environment == "generic" {
      get_flake_shell_hook "generic"
    } else {
      get_flake_shell_hook "generic"
      | append ""
      | append (get_flake_shell_hook $environment)
    } | to text
  )

  $"
    \{
      outputs = \{
        nixpkgs,
        nushell-syntax,
        ...
      \}: let
        supportedSystems = [
          \"x86_64-darwin\"
          \"x86_64-linux\"
        ];

        forEachSupportedSystem = f:
          nixpkgs.lib.genAttrs supportedSystems
          \(system:
            f \{
              pkgs = import nixpkgs \{inherit system;\};
            \}\);
      in \{
        devShells = forEachSupportedSystem \(\{pkgs\}: \{
          default = pkgs.mkShell \{
            packages = with pkgs; [
              ($packages | to text)
            ];

            shellHook = ''\n($shell_hook)'';
          \};
      \}\);
      \};
    \}
  " | alejandra --quiet --quiet
  | save --force $generated_flake
}

def get_modified [
  environment: string
  --generated
] {
  let base_directory = if $generated {
    if $environment == "dev" {
      pwd
    } else {
      get_build_directory $environment
    }
  } else {
    get_source_directory $environment
  }

  ls --directory $base_directory
  | get modified
}

def is_outdated [environment: string] {
  let source_modified = (get_modified $environment)
  let generated_modified = (get_modified --generated $environment)

  $source_modified > $generated_modified
}

# Build dev environments
export def main [
  environment?: string
  --force # Build environments even if up-to-date
  --skip-dev-flake # Skip building the dev flake.nix to avoid triggering direnv
] {
  let environments = if ($environment | is-empty) {
    eza ../src
    | lines
  } else {
    [$environment]
  }

  let environments = if $force {
    $environments
  } else {
    $environments
    | filter {|environment| not (is_outdated $environment)}
  }

  $environments
  | par-each {
      |environment|

      print $"Building ($environment)..."

      let source_directory = (get_source_directory $environment)
      let build_directory = (get_build_directory $environment)

      if $environment != "dev" {
        rm --recursive --force $build_directory
      }

      let source_files = (
        fd --hidden "" $source_directory
        | lines
        | append (
          fd "" (get_source_directory generic | path join scripts)
          | lines
        )
      )

      let directories = (
        $source_files
        | path dirname
        | uniq
        | filter {|directory| $directory != $source_directory}
        | each {|directory| get_build_path $environment $directory}
        | uniq
      )

      for directory in $directories {
        mkdir $directory
      }

      $source_files
      | filter {
          |file|

          ($file | path basename) not-in [.gitignore .pre-commit-config.yaml]
        }
      | filter {|item| ($item | path type) != dir}
      | each {|file| cp $file (get_build_path $environment $file)}

      let justfile = (get_justfile (get_source_directory generic))
      let environment_justfile_name = $"($environment).just"

      let environment_justfile = (
        $source_directory
        | path join $"just/($environment_justfile_name)"
      )

      if (
        $environment_justfile
        | path exists
      ) {
        let mod = $"mod ($environment) \"just/($environment).just\""

        let unique_environment_recipes = (
          get_recipes $environment_justfile
          | filter {
              |recipe|

              $recipe not-in (
                get_recipes $justfile
              )
          }
        )

        open $justfile
        | append (
            $"mod ($environment) \"just/($environment).just\""
            | append (
                $unique_environment_recipes
                | each {|recipe| create_environment_recipe $environment $recipe}
              )
          | str join "\n\n"
          )
        | to text
        | save --force (get_justfile (get_build_directory $environment))
      }

      get_gitignore_source generic
      | append (get_gitignore_source $environment)
      | uniq
      | sort
      | to text
      | save --force (
          $build_directory
          | path join ".gitignore"
      )

      let pre_commit_config_filename = ".pre-commit-config.yaml"

      let environment_config_path = (
        $source_directory
        | path join $pre_commit_config_filename
      )

      let generic_config = (
        open (
          get_source_directory generic
          | path join $pre_commit_config_filename
        ) | get repos
      )

      let generated_config_path = (
        $build_directory
        | path join ".pre-commit-config.yaml"
      )

      update_pre_commit_update generic

      let repos = if ($environment_config_path | path exists) {
        update_pre_commit_update $environment

        let environment_config = (open $environment_config_path | get repos)

        merge_records_by_key $generic_config $environment_config repo
      } else {
        $generic_config
      }

      {repos: $repos}
      | to yaml
      | save --force $generated_config_path

      let skip_flake = if $environment == "dev" and $skip_dev_flake {
        true
      } else {
        false
      }

      if not $skip_flake {
        let generated_flake = (get_generated_flake $environment)

        merge_flake_outputs $environment $generated_flake
        merge_flake_inputs $environment $generated_flake
      }
    }
  | null
}
