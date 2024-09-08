# View help text
@help *recipe:
    ../scripts/c/help.nu {{ recipe }}

# Remove compiled files
@clean *help:
    ../scripts/c/clean.nu {{ help }}

# Compile
@compile *help:
    ../scripts/c/compile.nu {{ help }}

# Run
@run *args:
    ../scripts/c/run.nu {{ args }}
