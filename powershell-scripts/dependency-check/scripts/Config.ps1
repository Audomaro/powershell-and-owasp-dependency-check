# Path environments
$Env:DEV_TOOLS_PATHS = "C:\dev-tools"
$Env:JAVA_HOME = "${Env:DEV_TOOLS_PATHS}\java"
$Env:DEPENDENCY_CHECK = "${Env:DEV_TOOLS_PATHS}\dependency-check\bin"
$Env:PATH = "$Env:PATH;${Env:DEV_TOOLS_PATHS};${Env:JAVA_HOME}\bin;${Env:DEPENDENCY_CHECK};${Env:NUGET};"
$env:JAVA_OPTS = "--add-modules jdk.incubator.vector"

# Message Colors
$Env:COLOR_SKIP = "Gray"
$Env:COLOR_INFO = "Cyan"
$Env:COLOR_SUCC = "Green"