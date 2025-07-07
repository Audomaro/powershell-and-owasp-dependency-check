function GenerateCvss3Summary {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CsvPath
    )

    if (-not (Test-Path $CsvPath)) {
        Write-Error "CSV file not found: ${CsvPath}"
        return
    }

    $csvName = [System.IO.Path]::GetFileNameWithoutExtension($CsvPath)
    $csvDir = [System.IO.Path]::GetDirectoryName($CsvPath)
    $outputPath = Join-Path $csvDir "${csvName}.txt"

    # Load CSV and filter only entries with CVSSv3_BaseSeverity
    $vulns = Import-Csv $CsvPath | Where-Object { $_.CVSSv3_BaseSeverity -ne "" }

    # Group by CVE to remove duplicates
    $uniqueVulns = $vulns | Group-Object CVE | ForEach-Object { $_.Group[0] }

    # Initialize counters
    $summary = @{
        critical = 0
        high     = 0
        medium   = 0
        low      = 0
    }

    # Count severities
    foreach ($v in $uniqueVulns) {
        $sev = $v.CVSSv3_BaseSeverity.ToLower()
        if ($summary.ContainsKey($sev)) {
            $summary[$sev]++
        }
    }

    # Prepare summary section
    $lines = @()
    $lines += "----------[Summary]----------"
    $lines += "critical: $($summary.critical)"
    $lines += "high:     $($summary.high)"
    $lines += "medium:   $($summary.medium)"
    $lines += "low:      $($summary.low)"
    $lines += ""

    # Sort and group by severity
    $severityOrder = @("critical", "high", "medium", "low")
    foreach ($severity in $severityOrder) {
        $group = $uniqueVulns | Where-Object { $_.CVSSv3_BaseSeverity.ToLower() -eq $severity }

        if ($group.Count -gt 0) {
            $lines += "----------[${severity}]----------"
            foreach ($v in $group | Sort-Object CVE) {
                $lines += "cve: $($v.CVE)"
                $lines += "issue: $($v.Vulnerability)"
                $lines += ""
            }
        }
    }

    # Save to file
    $lines | Set-Content -Encoding UTF8 $outputPath
    Write-Host "Summary saved to '$outputPath'" -ForegroundColor $Env:COLOR_SUCC
}
