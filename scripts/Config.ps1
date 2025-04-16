$DEV_TOOLS_PATHS = "C:\dev-tools"
$Env:JAVA_HOME = "${DEV_TOOLS_PATHS}\java"
$Env:DEPENDENCY_CHECK = "${DEV_TOOLS_PATHS}\dependency-check\bin"
$Env:PATH = "$Env:PATH;${Env:JAVA_HOME}\bin;${Env:DEPENDENCY_CHECK};"
