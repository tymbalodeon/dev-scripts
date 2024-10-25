# View help text
@help *recipe:
    ../scripts/environments/help.nu {{ recipe }}

# Build dev environments
[no-cd]
@build *args:
    ./scripts/environments/build.nu {{ args }}

# Run an environment Justfile
[no-cd]
@justfile *args:
    ./scripts/environments/justfile.nu {{ args }}

# Update all .pre-commit-config.yaml files
[no-cd]
@pre-commit-update *help:
    ./scripts/environments/pre-commit-update.nu {{ help }}

# Run tests
[no-cd]
@test *args:
    ./scripts/environments/test.nu {{ args }}
