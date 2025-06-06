# PowerShell & OWASP Dependency-Check

This PowerShell utility facilitates the execution of the OWASP Security Scan tool across multiple repository paths.

## Before Executing

Before running the script, you must configure the Java and OWASP Dependency-Check paths in the `config.ps1` file.

> It is recommended to install both tools under a common directory, such as:
>
> ```bash
> C:/
> └── dev-tools/
>     ├── java/
>     └── dependency-check/
> ```

Example configuration:

```powershell
$DEV_TOOLS_PATHS = "C:\dev-tools"
$Env:JAVA_HOME = "${DEV_TOOLS_PATHS}\java"
$Env:DEPENDENCY_CHECK = "${DEV_TOOLS_PATHS}\dependency-check\bin"
$Env:PATH = "$Env:PATH;${Env:JAVA_HOME}\bin;${Env:DEPENDENCY_CHECK};"
```

## How to Use It

To use this tool, you must provide a text file containing entries in the following format:

```txt
Solution Name #1|https://my.server/my-repo-01.git
Solution Name #2|git@my.server:my-repo-02.git
Solution Name #3|https://my.server/my-repo-03.git
```

Example usage (in a PowerShell terminal):

```powershell
.\ProcessRepos.ps1
```

Default parameter values:

- `-RepoListPath = "${PSScriptRoot}\repos\repo-list.txt"`
- `-WorkDir = "${PSScriptRoot}\repos"`

> If using SSH repositories, the terminal will prompt for your private key passphrase during execution.

## Updating the OWASP Dependency-Check Database

OWASP Dependency-Check relies on an up-to-date vulnerability database.
To update it manually before scanning, you can run the following PowerShell script:

```powershell
.\UpdateOwaspDb.ps1 [-UseProxy $true|$false]
```

## PowerShell Scripts Overview

This section provides a detailed explanation of each PowerShell script used in this automation workflow.

Each script handles a specific task such as cloning repositories, installing dependencies, running security scans, or generating CVSSv3-based summaries.

### `ProcessRepos.ps1`

Main automation script that coordinates the full workflow:

1. Clone Git repositories
2. Install project dependencies (npm and NuGet)
3. Run security scans using OWASP Dependency-Check
4. Generate CVSSv3 vulnerability summaries

#### Loads the following support scripts:

- `Config.ps1`: Sets environment variables and color codes
- `DownloadRepoGit.ps1`: Clones Git repositories
- `RunSecScan.ps1`: Runs OWASP Dependency-Check
- `InstallNpmDependencies.ps1`: Installs Node.js dependencies
- `InstallNugetPackages.ps1`: Installs .NET dependencies
- `GenerateCvss3Summary.ps1`: Creates severity-based summaries

### `Config.ps1`

Defines environment variables used across all scripts, including:

- **Tool Paths**
  - `DEV_TOOLS_PATHS`: Base path for dev tools
  - `JAVA_HOME`: Path to Java
  - `DEPENDENCY_CHECK`: Path to Dependency-Check
- **Message Colors**
  - `COLOR_SKIP`: Gray (skipped)
  - `COLOR_INFO`: Cyan (informational)
  - `COLOR_SUCC`: Green (success)

### `DownloadRepoGit.ps1`

Clones a Git repository into a specified directory.

| Parameter | Required | Description                          |
|-----------|----------|--------------------------------------|
| `UrlGit`  | ✅ Yes    | Git repository URL to clone.         |
| `Dest`    | ❌ No     | Target directory for the repository. |

### `InstallNpmDependencies.ps1`

Installs Node.js dependencies using `npm ci`.
Skips installation if a `node_modules` folder already exists.

| Parameter     | Required | Description                                           |
|---------------|----------|-------------------------------------------------------|
| `ProjectPath` | ✅ Yes    | Root directory to look for `package.json` recursively |

### `InstallNugetPackages.ps1`

Restores NuGet packages for all `.sln` files found under a given directory.
Skips restore if a `packages` folder is already present next to the `.sln`.

| Parameter     | Required | Description                                    |
|---------------|----------|------------------------------------------------|
| `ProjectPath` | ✅ Yes    | Directory where `.sln` files should be located |

### `RunSecScan.ps1`

Runs a Dependency-Check scan for a specific project and outputs a `.csv` report.

| Parameter      | Required | Description                                                                 |
|----------------|----------|-----------------------------------------------------------------------------|
| `ProjectName`  | ✅ Yes    | Project name (used to name the CSV file)                                    |
| `ProjectPath`  | ✅ Yes    | Directory to scan                                                           |
| `WorkDir`      | ✅ Yes    | Output folder for the `.csv` report                                         |
| `excludePaths` | ❌ No     | Additional exclusion patterns (defaults include `node_modules`, `packages`) |

### `GenerateCvss3Summary.ps1`

Reads a `.csv` report and outputs a plain-text summary grouped by CVSSv3 severity.
The report groups CVEs under headings like `----------[critical]----------`.

| Parameter | Required | Description                                           |
|-----------|----------|-------------------------------------------------------|
| `CsvPath` | ✅ Yes    | Path to the CSV file generated by `dependency-check`. |

## Where to Get the Tools

- **Using `winget`**:

  - PowerShell: `winget install --id Microsoft.PowerShell --source winget`
  - Git: `winget install -e --id Git.Git`
- **Manual Downloads**:

  - PowerShell: https://github.com/PowerShell/PowerShell
  - Git: https://git-scm.com/
  - OWASP Dependency-Check: https://owasp.org/www-project-dependency-check/
  - Java Zulu: https://www.azul.com/downloads/?package=jdk#zulu
