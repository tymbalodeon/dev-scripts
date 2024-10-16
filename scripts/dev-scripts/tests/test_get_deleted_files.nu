use std assert

use ../build.nu get_deleted_files

let build_files = [
  build/python/.gitignore
  build/python/.pre-commit-config.yaml
  build/python/Justfile
  build/python/cog.toml
  build/python/flake.nix
  build/python/just/python.just
  build/python/nix/python.nix
  build/python/pyproject.toml
  build/python/scripts/annotate.nu
  build/python/scripts/check.nu
  build/python/scripts/deps.nu
  build/python/scripts/diff-env.nu
  build/python/scripts/domain.nu
  build/python/scripts/find-recipe.nu
  build/python/scripts/help.nu
  build/python/scripts/history.nu
  build/python/scripts/init.nu
  build/python/scripts/issue.nu
  build/python/scripts/python/add.nu
  build/python/scripts/python/build.nu
  build/python/scripts/python/clean.nu
  build/python/scripts/python/command.nu
  build/python/scripts/python/coverage.nu
  build/python/scripts/python/deps.nu
  build/python/scripts/python/help.nu
  build/python/scripts/python/install.nu
  build/python/scripts/python/profile.nu
  build/python/scripts/python/release.nu
  build/python/scripts/python/remove.nu
  build/python/scripts/python/run.nu
  build/python/scripts/python/shell.nu
  build/python/scripts/python/test.nu
  build/python/scripts/python/update-deps.nu
  build/python/scripts/python/version.nu
  build/python/scripts/release.nu
  build/python/scripts/remote.nu
  build/python/scripts/stats.nu
  build/python/scripts/update-deps.nu
  build/python/scripts/view-source.nu
]

let test_data = [
  {
    source_files: [
      src/python/.gitignore
      src/python/.pre-commit-config.yaml
      src/python/just/python.just
      src/python/nix/python.nix
      src/python/scripts/python/add.nu
      src/python/scripts/python/build.nu
      src/python/scripts/python/clean.nu
      src/python/scripts/python/command.nu
      src/python/scripts/python/coverage.nu
      src/python/scripts/python/deps.nu
      src/python/scripts/python/help.nu
      src/python/scripts/python/install.nu
      src/python/scripts/python/profile.nu
      src/python/scripts/python/release.nu
      src/python/scripts/python/remove.nu
      src/python/scripts/python/run.nu
      src/python/scripts/python/shell.nu
      src/python/scripts/python/test.nu
      src/python/scripts/python/update-deps.nu
      src/python/scripts/python/version.nu
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
    ]

    build_files: $build_files
    expected_deleted_files: []
  }

  {
    source_files: [
      # src/python/.gitignore
      src/python/.pre-commit-config.yaml
      src/python/just/python.just
      src/python/nix/python.nix
      # src/python/scripts/python/add.nu
      src/python/scripts/python/build.nu
      src/python/scripts/python/clean.nu
      src/python/scripts/python/command.nu
      src/python/scripts/python/coverage.nu
      src/python/scripts/python/deps.nu
      src/python/scripts/python/help.nu
      src/python/scripts/python/install.nu
      src/python/scripts/python/profile.nu
      src/python/scripts/python/release.nu
      src/python/scripts/python/remove.nu
      src/python/scripts/python/run.nu
      src/python/scripts/python/shell.nu
      src/python/scripts/python/test.nu
      src/python/scripts/python/update-deps.nu
      src/python/scripts/python/version.nu
      src/generic/.gitignore
      src/generic/.pre-commit-config.yaml
      src/generic/Justfile
      src/generic/cog.toml
      src/generic/flake.nix
      # src/generic/pyproject.toml
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
      # src/generic/scripts/view-source.nu
    ]

    build_files: $build_files

    expected_deleted_files: [
      build/python/pyproject.toml
      build/python/scripts/python/add.nu
      build/python/scripts/view-source.nu
    ]
  }
]

for test in $test_data {
  let actual_deleted_files = (
    get_deleted_files python $test.source_files $test.build_files
  )

  assert equal $actual_deleted_files $test.expected_deleted_files
}
