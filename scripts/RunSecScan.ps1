function RunSecScan {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$WorkDir,

        [Parameter(Mandatory = $false)]
        [string]$excludePaths
    )

    $outputCsv = Join-Path -Path $WorkDir -ChildPath "${ProjectName}.csv"

    $excludePaths += ",**/node_modules/**,**/packages/**"

    & "dependency-check.bat" `
        --project "${ProjectName}" `
        -s "${ProjectPath}" `
        -o "${outputCsv}" `
        -n `
        --format CSV `
        --disableOssIndex `
        --exclude "**/node_modules/**,**/packages/**" `
        --disableComposer `
        --disableArchive `
        --disableJar `
        --disableAutoconf `
        --disableCmake `
        --disablePip `
        --disablePipfile `
        --nodeAudit `
        --disableYarnAudit `
        --disableAssembly `
        --disableCentral `
        --disableRetireJS `
        --enableExperimental
}
