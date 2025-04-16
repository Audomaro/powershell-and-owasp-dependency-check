# Powershell & OWASP Dependency Check

This powershell is a utility that allows to facilitate the execution of the OWASP Security Scan tool over multiple repository paths.

## Before executing

Before executing you must configure the JAVA and OWASP dependecy check paths in the `config.ps1` file.

> It is recommended that if they are not installed, they should be in the same path.
>
> ```bash
> c:/
> └── dev-tools/
>     ├── java/
>     └── dependency-check/
> ```

Configuration example:

```powershell
$DEV_TOOLS_PATHS = "C:\dev-tools"
$Env:JAVA_HOME = "${DEV_TOOLS_PATHS}\java"
$Env:DEPENDENCY_CHECK = "${DEV_TOOLS_PATHS}\dependency-check\bin"
$Env:PATH = "$Env:PATH;${Env:JAVA_HOME}\bin;${Env:DEPENDENCY_CHECK};"
```

## How to use it?

To use this tool you must provide a file with the following format:

```txt
Solition Name #1|https://my.server/my-repo-01.git or git@my.server:my-repo-01.git
Solition Name #2|https://my.server/my-repo-02.git or git@my.server:my-repo-02.git
Solition Name #3|https://my.server/my-repo-03.git or git@my.server:my-repo-03.git
```

Example of use; to be executed on a powershell terminal:

```powershell
./ProcessRepos.ps1
```

The default values are:

- RepoListPath = `"${PSScriptRoot}\repos\repo-list.txt"`
- WorkDir = `"${PSScriptRoot}\repos"`

The `repos` path in this repository is ignored.

> If shh repositories are added, the terminal will ask you for the key password when you run the script.

## Where get the tools?

- On winget
  - Powershell: `winget install --id Microsoft.PowerShell --source winget`
  - Git: `winget install -e --id Git.Git`
- Others
  - Powershell: [https://github.com/PowerShell/PowerShell](https://github.com/PowerShell/PowerShell)
  - Git: [https://git-scm.com/](https://git-scm.com/)
  - OWASP Dependecy Check: [https://owasp.org/www-project-dependency-check/](https://owasp.org/www-project-dependency-check/)
  - Java Zulu: [https://www.azul.com/downloads/?package=jdk#zulu](https://www.azul.com/downloads/?package=jdk#zulu)
