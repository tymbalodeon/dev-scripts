# View help text
@help *recipe:
    ../scripts/java/help.nu {{ recipe }}

# Remove compiled files
@clean *help:
    ../scripts/java/clean.nu {{ help }}

# Compile
@compile *help:
    ../scripts/java/compile.nu {{ help }}

# Run
@run *args:
    ../scripts/java/run.nu {{ args }}
