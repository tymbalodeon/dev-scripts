use std assert

use ../build.nu get_pre_commit_config_yaml
use ../build.nu merge_gitignores
use ../build.nu merge_justfiles
use ../build.nu merge_pre_commit_configs

let generic_gitignore = ".config
.direnv
.envrc
.pdm-python
.venv
"

let environment_gitignore = "*.pyc
.coverage
__pycache__/
build/
dist/
"

let actual_gitignore = (
    merge_gitignores $generic_gitignore $environment_gitignore
)

let expected_gitignore = "*.pyc
.config
.coverage
.direnv
.envrc
.pdm-python
.venv
__pycache__/
build/
dist/
"

assert equal $actual_gitignore $expected_gitignore

let generic_justfile = ($env.FILE_PWD | path join generic-justfile.just)
let environment_justfile = ($env.FILE_PWD | path join environment-justfile.just)

let actual_justfile = (
  merge_justfiles python $generic_justfile $environment_justfile
)

let expected_justfile = "# View help text
@help *recipe:
    ./scripts/help.nu {{ recipe }}

# View file annotated with version control information
[no-cd]
@annotate *filename:
    ./scripts/annotate.nu {{ filename }}

# Check flake and run pre-commit hooks
@check *args:
    ./scripts/check.nu {{ args }}

# List dependencies
@deps *args:
    ./scripts/deps.nu {{ args }}

# View the diff between environments
@diff-env *args:
    ./scripts/diff-env.nu {{ args }}

# Search available `just` recipes
[no-cd]
[no-exit-message]
@find-recipe *search_term:
    ./scripts/find-recipe.nu {{ search_term }}

# View project history
[no-cd]
@history *args:
    ./scripts/history.nu {{ args }}

# Initialize direnv environment
@init *help:
    ./scripts/init.nu {{ help }}

# View issues
@issue *args:
    ./scripts/issue.nu {{ args }}

# Create a new release
@release *preview:
    ./scripts/release.nu  {{ preview }}

# View remote repository
@remote *web:
    ./scripts/remote.nu  {{ web }}

# View repository analytics
@stats *help:
    ./scripts/stats.nu {{ help }}

# Update dependencies
@update-deps *help:
    ./scripts/update-deps.nu {{ help }}

# View the source code for a recipe
[no-cd]
@view-source *recipe:
    ./scripts/view-source.nu {{ recipe }}

mod python \"just/python.just\"

# Alias for `python add`
@add *args:
    just python add {{ args }}

# Alias for `python build`
@build *args:
    just python build {{ args }}

# Alias for `python clean`
@clean *args:
    just python clean {{ args }}

# Alias for `python coverage`
@coverage *args:
    just python coverage {{ args }}

# Alias for `python install`
@install *args:
    just python install {{ args }}

# Alias for `python profile`
@profile *args:
    just python profile {{ args }}

# Alias for `python remove`
@remove *args:
    just python remove {{ args }}

# Alias for `python run`
@run *args:
    just python run {{ args }}

# Alias for `python shell`
@shell *args:
    just python shell {{ args }}

# Alias for `python test`
@test *args:
    just python test {{ args }}
"

assert equal $actual_justfile $expected_justfile

let generic_pre_commit_config = "repos:
  - repo: https://gitlab.com/vojko.pribudic.foss/pre-commit-update
    rev: v0.5.0
    hooks:
      - id: pre-commit-update
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.4
    hooks:
      - id: gitleaks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-merge-conflict
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
  - repo: https://github.com/DavidAnson/markdownlint-cli2
    rev: v0.14.0
    hooks:
      - id: markdownlint-cli2
        args:
          - --fix
  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.1.0
    hooks:
      - id: prettier
        types:
          - markdown
  - repo: https://github.com/kamadorueda/alejandra
    rev: 3.0.0
    hooks:
      - id: alejandra-system
  - repo: https://github.com/astro/deadnix
    rev: v1.2.1
    hooks:
      - id: deadnix
        args:
          - --edit
  - repo: local
    hooks:
      - id: flake-checker
        name: flake-checker
        entry: flake-checker
        language: system
        pass_filenames: false
      - id: justfile
        name: justfile
        entry: just --fmt --unstable
        language: system
        pass_filenames: false
      - id: statix
        name: statix
        entry: statix fix
        language: system
        pass_filenames: false
      - id: yamlfmt
        name: yamlfmt
        entry: yamlfmt
        language: system
        pass_filenames: false
  - repo: https://github.com/lycheeverse/lychee.git
    rev: v0.15.1
    hooks:
      - id: lychee
        args: [\"--no-progress\", \".\"]
        pass_filenames: false
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v3.4.0
    hooks:
      - id: conventional-pre-commit
        stages:
          - commit-msg
"

let environment_pre_commit_config = "repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-json
      - id: check-toml
      - id: pretty-format-json
        args:
          - --autofix
  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.1.0
    hooks:
      - id: prettier
        types:
          - json
  - repo: local
    hooks:
      - id: taplo
        name: taplo
        entry: taplo format
        language: system
"

let actual_pre_commit_conifg = (
    get_pre_commit_config_yaml (
      merge_pre_commit_configs 
        $generic_pre_commit_config 
        $environment_pre_commit_config
    )
)

let expected_pre_commit_config = "repos:
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v4.6.0
  hooks:
  - id: check-json
  - id: check-toml
  - id: pretty-format-json
    args:
    - --autofix
  - id: check-merge-conflict
  - id: check-yaml
  - id: end-of-file-fixer
  - id: trailing-whitespace
- repo: https://github.com/pre-commit/mirrors-prettier
  rev: v3.1.0
  hooks:
  - id: prettier
    types:
    - json
- repo: local
  hooks:
  - id: taplo
    name: taplo
    entry: taplo format
    language: system
  - id: flake-checker
    name: flake-checker
    entry: flake-checker
    language: system
    pass_filenames: false
  - id: justfile
    name: justfile
    entry: just --fmt --unstable
    language: system
    pass_filenames: false
  - id: statix
    name: statix
    entry: statix fix
    language: system
    pass_filenames: false
  - id: yamlfmt
    name: yamlfmt
    entry: yamlfmt
    language: system
    pass_filenames: false
- repo: https://gitlab.com/vojko.pribudic.foss/pre-commit-update
  rev: v0.5.0
  hooks:
  - id: pre-commit-update
- repo: https://github.com/gitleaks/gitleaks
  rev: v8.18.4
  hooks:
  - id: gitleaks
- repo: https://github.com/DavidAnson/markdownlint-cli2
  rev: v0.14.0
  hooks:
  - id: markdownlint-cli2
    args:
    - --fix
- repo: https://github.com/kamadorueda/alejandra
  rev: 3.0.0
  hooks:
  - id: alejandra-system
- repo: https://github.com/astro/deadnix
  rev: v1.2.1
  hooks:
  - id: deadnix
    args:
    - --edit
- repo: https://github.com/lycheeverse/lychee.git
  rev: v0.15.1
  hooks:
  - id: lychee
    args:
    - --no-progress
    - .
    pass_filenames: false
- repo: https://github.com/compilerla/conventional-pre-commit
  rev: v3.4.0
  hooks:
  - id: conventional-pre-commit
    stages:
    - commit-msg
" 

assert equal $actual_pre_commit_conifg $expected_pre_commit_config
