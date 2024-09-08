# View help text
@help *recipe:
    ./scripts/dev-scripts/help.nu {{ recipe }}

# Build dev environments
@build *args:
    ../scripts/dev-scripts/build.nu {{ args }}

# Run an environment Justfile
@justfile *args:
    ./scripts/dev-scripts/justfile.nu {{ args }}

# List available environments and files
@list *help:
    ./scripts/dev-scripts/list.nu {{ help }}
