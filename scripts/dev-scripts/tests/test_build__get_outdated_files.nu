use std assert

use ../../build.nu get_outdated_files

let files = (
  [
    src/generic/.gitignore
    src/generic/.pre-commit-config.yaml
    src/generic/Justfile
    src/generic/cog.toml
    src/generic/flake.nix
    src/generic/pyproject.toml
    src/generic/scripts/annotate.nu
    src/generic/scripts/check.nu
    src/generic/scripts/deps.nu
    src/generic/scripts/diff-env.nu
    src/generic/scripts/domain.nu
    src/generic/scripts/find-recipe.nu
    src/generic/scripts/help.nu
    src/generic/scripts/history.nu
    src/generic/scripts/init.nu
    src/generic/scripts/issue.nu
    src/generic/scripts/release.nu
    src/generic/scripts/remote.nu
    src/generic/scripts/stats.nu
    src/generic/scripts/update-deps.nu
    src/generic/scripts/view-source.nu
  ] | wrap environment
  | merge (
      [
      .gitignore
      .pre-commit-config.yaml
      Justfile
      cog.toml
      flake.nix
      pyproject.toml
      scripts/annotate.nu
      scripts/check.nu
      scripts/deps.nu
      scripts/diff-env.nu
      scripts/domain.nu
      scripts/find-recipe.nu
      scripts/help.nu
      scripts/history.nu
      scripts/init.nu
      scripts/issue.nu
      scripts/release.nu
      scripts/remote.nu
      scripts/stats.nu
      scripts/update-deps.nu
      scripts/view-source.nu
    ] | wrap local
  )
)

let old = "2024-09-20"
let new = "2024-09-21"

let test_data = [
  {
    files: (
      $files
      | insert environment_modified $old
      | insert local_modified $old
    )
    expected_outdated_files: []
  }
  {
    files: (
      $files
      | insert environment_modified $old
      | insert local_modified $new
    )
    expected_outdated_files: []
  }
  {
    files: (
      $files
      | insert environment_modified $new
      | insert local_modified $old
    )
    expected_outdated_files: $files.environment
  }
]

for test in $test_data {
  let actual_outdated_files = (get_outdated_files $test.files)

  assert equal $actual_outdated_files $test.expected_outdated_files
}

# FIXME
# let new_file = "src/generic/new"

# let new_row = (
#   [
#     [
#       environment
#       environment_modified
#     ];

#     [$new_file $new]
#   ]
# )


# let actual_outdated_files = (get_outdated_files $files)

# assert equal $actual_outdated_files [$new_file]
