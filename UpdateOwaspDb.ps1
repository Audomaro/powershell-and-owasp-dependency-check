param(
    [bool]$UseProxy = $false
)

# Load functions from an external script located in the "scripts" folder
. "${PSScriptRoot}\scripts\Config.ps1"

# Set Java environment options only if proxy usage is enabled
if ($UseProxy) {
    # Define variables for proxy settings and trustStore configuration (for SSL/TLS)
    $proxyHost = "[http://your.proxy]"            # Proxy server address (replace with actual)
    $proxyPort = "[port]"                         # Proxy port (e.g., 8080)
    $trustStore = "[c:\some\path\file.jks]"       # Path to the JKS trustStore file
    $trustStorePassword = "[changeit]"            # TrustStore password (handle securely)

    # Clear and set Java environment options
    $env:JAVA_TOOL_OPTIONS = ""                                                       # Clear any previous value
    $env:JAVA_TOOL_OPTIONS += "-Dhttps.proxyHost=$proxyHost "                         # Set proxy host
    $env:JAVA_TOOL_OPTIONS += "-Dhttps.proxyPort=$proxyPort "                         # Set proxy port
    $env:JAVA_TOOL_OPTIONS += "-Djavax.net.ssl.trustStore=$trustStore "               # Set path to trustStore
    $env:JAVA_TOOL_OPTIONS += "-Djavax.net.ssl.trustStorePassword=$trustStorePassword "  # Set trustStore password
}

# Run OWASP Dependency-Check in update-only mode to download the latest vulnerability database
& dependency-check.bat --updateonly
