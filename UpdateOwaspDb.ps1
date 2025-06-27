# Load functions from an external script located in the "scripts" folder
. "${PSScriptRoot}\scripts\Config.ps1"

& "dependency-check.bat" --updateonly 

# Test conetion to nvd database
# Invoke-WebRequest -Uri "https://services.nvd.nist.gov/rest/json/cves/2.0"
