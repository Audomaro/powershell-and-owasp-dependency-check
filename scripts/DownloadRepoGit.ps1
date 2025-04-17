function DownloadRepoGit {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UrlGit,

        [Parameter(Mandatory = $false)]
        [string]$Dest
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "Git is not installed or is not in the PATH."
        return
    }

    try {
        git clone $UrlGit $Dest
        Write-Host "Repository cloned in: ${Dest}" -ForegroundColor $Env:COLOR_SUCC
    }
    catch {
        Write-Error "Error when cloning repository from ${UrlGit}: $_"
    }
}
