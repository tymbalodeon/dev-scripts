# View help text
@help *recipe:
    ../scripts/dev-scripts/help.nu {{ recipe }}

# Build dev environments
[no-cd]
@build *args:
    ./scripts/dev-scripts/build.nu {{ args }}

# Run an environment Justfile
[no-cd]
@justfile *args:
    ./scripts/dev-scripts/justfile.nu {{ args }}

# Run tests
[no-cd]
@test *args:
    ./scripts/dev-scripts/test.nu {{ args }}
