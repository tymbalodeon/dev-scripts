#!/usr/bin/env nu

def get_source_directory [environment: string] {
  $"src/($environment)"
}

export def get_build_directory [environment: string] {
  if $environment == "dev-scripts" {
    ""
  } else {
    $"build/($environment)"
  }
}

def get_settings [environment: string] {
  {
    environment: $environment
    generic_source_directory: (get_source_directory generic)
    source_directory: (get_source_directory $environment)
    build_directory: (get_build_directory $environment)
  }
}

def get_modified [
  environment: string
  --generated
] {
  let base_directory = if $generated {
    if $environment == "dev-scripts" {
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

def get_source_files [
  settings: record<
    environment: string
    generic_source_directory: string
    source_directory: string
    build_directory: string
  >
] {
  fd --hidden "" $settings.source_directory
  | lines
  | append (
      fd "" ($settings.generic_source_directory | path join scripts)
      | lines
    )
}

def get_build_path [environment: string path: string] {
  get_build_directory $environment
  | path join (
    $path
    | str replace --regex "src/[a-zA-Z-_]+/" ""
  )
}

def get_source_directories [
  source_files: list<string>
  settings: record<
    environment: string
    generic_source_directory: string
    source_directory: string
    build_directory: string
  >
] {
  $source_files
  | path dirname
  | uniq
  | filter {|directory| $directory != $settings.source_directory}
  | each {|directory| get_build_path $settings.environment $directory}
  | uniq
}

def copy_source_files [
  settings: record<
    environment: string
    generic_source_directory: string
    source_directory: string
    build_directory: string
  >
] {
  let source_files = (get_source_files $settings)

  let directories = (
    get_source_directories $source_files $settings
  )

  for directory in $directories {
    mkdir $directory
  }

  let source_files = (
    $source_files
    | filter {
        |file|

        ($file | path basename) not-in [.gitignore .pre-commit-config.yaml]
      }
    | filter {|item| ($item | path type) != dir}
  )

  for file in $source_files {
    cp $file (get_build_path $settings.environment $file)
  }
}

def get_justfile [base_directory: string] {
  $base_directory 
  | path join Justfile
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

def copy_justfile [
  settings: record<
    environment: string
    generic_source_directory: string
    source_directory: string
    build_directory: string
  >
] {
  let justfile = (get_justfile $settings.generic_source_directory)
  let environment_justfile = $"just/($settings.environment).just"

  let absolute_environment_justfile_path = (
    $settings.source_directory
    | path join $environment_justfile
  )

  if (
    $absolute_environment_justfile_path
    | path exists
  ) {
    let mod = $"mod ($settings.environment) ($environment_justfile)"

    let unique_environment_recipes = (
      get_recipes $absolute_environment_justfile_path
      | filter {
          |recipe|

          $recipe not-in (
            get_recipes $justfile
          )
      }
    )

    open $justfile
    | append (
        $"mod ($settings.environment) \"just/($settings.environment).just\""
        | append (
            $unique_environment_recipes
            | each {
                |recipe| 
                
                create_environment_recipe $settings.environment $recipe
              }
          )
      | str join "\n\n"
      )
    | to text
    | save --force (get_justfile $settings.build_directory)
  } else {
    cp $justfile $settings.build_directory
  }
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

def copy_gitignore [
  settings: record<
    environment: string
    generic_source_directory: string
    source_directory: string
    build_directory: string
  >
] {
  get_gitignore_source generic
  | append (get_gitignore_source $settings.environment)
  | uniq
  | sort
  | to text
  | save --force (
      $settings.build_directory
      | path join ".gitignore"
    )
}

def update_pre_commit_update [environment: string] {
  let directory = (get_source_directory $environment)

  try {
    cd $directory
    pdm run pre-commit-update out+err> /dev/null
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

def copy_pre_commit_config [
  settings: record<
    environment: string
    generic_source_directory: string
    source_directory: string
    build_directory: string
  >
] {
  let pre_commit_config_filename = ".pre-commit-config.yaml"

  let environment_config_path = (
    $settings.source_directory
    | path join $pre_commit_config_filename
  )

  let generic_config = (
    open (
      $settings.generic_source_directory
      | path join $pre_commit_config_filename
    ) | get repos
  )

  let generated_config_path = (
    $settings.build_directory
    | path join ".pre-commit-config.yaml"
  )

  update_pre_commit_update generic

  let repos = if ($environment_config_path | path exists) {
    update_pre_commit_update $settings.environment

    let environment_config = (open $environment_config_path | get repos)

    merge_records_by_key $generic_config $environment_config repo
  } else {
    $generic_config
  }

  {repos: $repos}
  | to yaml
  | save --force $generated_config_path
}

def get_flake [source_directory: string] {
  $source_directory
  | path join flake.nix
}

def get_flake_inputs [source_directory: string] {
  (
    nix eval
      --apply 'builtins.getAttr "inputs"'
      --file (get_flake $source_directory)
      --json
    | from json
  )
}

def get_generated_flake [
  settings: record<
    environment: string
    generic_source_directory: string
    source_directory: string
    build_directory: string
  >
] {
  if $settings.environment == "dev-scripts" {
    mktemp --tmpdir flake-XXX.nix
  } else {
    $settings.build_directory
    | path join flake.nix
  }
}

def merge_flake_inputs [
  generated_flake: string 
  settings: record<
    environment: string
    generic_source_directory: string
    source_directory: string
    build_directory: string
  >
] {
  mut merged_inputs = {}

  for directory in [
    $settings.generic_source_directory 
    $settings.source_directory
  ] {
    let inputs = (get_flake_inputs $directory)

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

  if $settings.environment == "dev-scripts" {
    cp $generated_flake flake.nix
    rm $generated_flake
  }
}

def get_flake_packages [source_directory: string] {
  open (get_flake $source_directory)
  | rg --multiline "packages = with pkgs; \\[(\n|.)+\\];"
  | lines
  | drop nth 0
  | drop
  | str trim
}

def get_flake_shell_hook [source_directory: string] {
  open (get_flake $source_directory)
  | rg --multiline "shellHook = ''(\n|.)+'';"
  | lines
  | drop nth 0
  | drop
  | str trim
}

def merge_flake_outputs [
  generated_flake: string 
  settings: record<
    environment: string
    generic_source_directory: string
    source_directory: string
    build_directory: string
  >
] {
  let packages = if $settings.environment == "generic" {
     get_flake_packages $settings.generic_source_directory
  } else {
    get_flake_packages $settings.generic_source_directory
    | append (get_flake_packages $settings.source_directory)
    | uniq
    | sort
  }

  let shell_hook = (
    if $settings.environment == "generic" {
      get_flake_shell_hook $settings.generic_source_directory
    } else {
      get_flake_shell_hook $settings.generic_source_directory
      | append ""
      | append (get_flake_shell_hook $settings.source_directory)
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

def copy_flake [
  settings: record<
    environment: string
    generic_source_directory: string
    source_directory: string
    build_directory: string
  >
] {
  let generated_flake = (get_generated_flake $settings)

  merge_flake_outputs $generated_flake $settings
  merge_flake_inputs $generated_flake $settings
}

# Build dev environments
export def main [
  environment?: string
  --force # Build environments even if up-to-date
  --skip-dev-flake # Skip building the dev flake.nix to avoid triggering direnv
] {
  let environments = if ($environment | is-empty) {
    eza src
    | lines
  } else {
    [$environment]
  }

  let environments = if $force {
    $environments
  } else {
    $environments
    | filter {|environment| is_outdated $environment}
  }

  $environments
  | par-each {
      |environment|

      print $"Building ($environment)..."

      let settings = (get_settings $environment)

      if $environment != "dev-scripts" {
        rm --recursive --force $settings.build_directory
      }

      copy_source_files $settings
      copy_justfile $settings
      copy_gitignore $settings
      copy_pre_commit_config $settings 

      if $environment != "dev-scripts" or not $skip_dev_flake {
        copy_flake $settings
      } 
    }
  | null
}
