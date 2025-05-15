Write-OutPut "================== VARIABLES DECLARADAS =================="
Get-ChildItem Env: | ForEach-Object { Write-Output "$($_.Name) = $($_.Value)" }
Write-OutPut "============================================================"
