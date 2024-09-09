set dotenv-load

# View help text
@help *recipe:
    ../scripts/zola/help.nu {{ recipe }}

# Serve the site
@start *args:
    ../scripts/zola/start.nu {{ args }}
