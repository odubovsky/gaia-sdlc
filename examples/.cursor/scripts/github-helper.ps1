param(
    [Parameter(Position = 0)]
    [string]$Action = ""
)

$ErrorActionPreference = "Stop"

function Say($Message) {
    Write-Host ""
    Write-Host $Message
}

function Info($Message) {
    Write-Host "[INFO] $Message"
}

function Warn($Message) {
    Write-Host "[WARN] $Message"
}

function Err($Message) {
    Write-Host "[ERROR] $Message"
}

function Is-GitRepo {
    git rev-parse --is-inside-work-tree *> $null
    return ($LASTEXITCODE -eq 0)
}

function Get-RepoRoot {
    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) { return "" }
    return ($root | Out-String).Trim()
}

function At-RepoRoot {
    $root = Get-RepoRoot
    if ([string]::IsNullOrWhiteSpace($root)) { return $false }
    return ((Get-Location).Path -eq $root)
}

function Has-Commits {
    git rev-parse --verify HEAD *> $null
    return ($LASTEXITCODE -eq 0)
}

function Get-CurrentBranch {
    $branch = git branch --show-current 2>$null
    if ($LASTEXITCODE -ne 0) { return "" }
    return ($branch | Out-String).Trim()
}

function Has-OriginRemote {
    git remote get-url origin *> $null
    return ($LASTEXITCODE -eq 0)
}

function Get-OriginUrl {
    $url = git remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0) { return "" }
    return ($url | Out-String).Trim()
}

function Test-RemoteRepoReachable {
    git ls-remote origin *> $null
    return ($LASTEXITCODE -eq 0)
}

function Get-CurrentFolderName {
    return Split-Path -Leaf (Get-Location)
}

function Get-RepoRootName {
    $root = Get-RepoRoot
    if ([string]::IsNullOrWhiteSpace($root)) { return "" }
    return Split-Path -Leaf $root
}

function Get-LatestCommitShort {
    $commit = git log -1 --pretty=format:'%h - %s' 2>$null
    if ($LASTEXITCODE -ne 0) { return "" }
    return ($commit | Out-String).Trim()
}

function Default-RepoName {
    if (Is-GitRepo) {
        return Get-RepoRootName
    }
    return Split-Path -Leaf (Get-Location)
}

function Default-CommitMessage {
    if ($env:GITHUB_HELPER_COMMIT_MESSAGE) { return $env:GITHUB_HELPER_COMMIT_MESSAGE }
    return "Update files"
}

function Initial-CommitMessage {
    if ($env:GITHUB_HELPER_INITIAL_COMMIT_MESSAGE) { return $env:GITHUB_HELPER_INITIAL_COMMIT_MESSAGE }
    return "Initial commit"
}

function Show-GitMissingMessage {
@"
Git is not installed on this computer.

Git is required for all actions in github-helper because it tracks your project files and history.

What to do now:

1. Open PowerShell.
   - Click Start
   - Type: PowerShell
   - Open "Windows PowerShell" or "PowerShell"

2. Install Git.

   Windows:
   - Website: https://git-scm.com/download/win
   - Or run this in PowerShell:
     winget install --id Git.Git -e

3. After installation finishes, close and reopen Cursor if needed.

4. Go back to the Cursor chat.

5. Run this command again:
   /github-helper
"@ | Write-Host
}

function Show-GhMissingMessage {
@"
GitHub CLI (gh) is not installed on this computer.

GitHub CLI is needed when github-helper creates a GitHub repository for you
or connects this project to GitHub automatically.

What to do now:

1. Open PowerShell.
   - Click Start
   - Type: PowerShell
   - Open "Windows PowerShell" or "PowerShell"

2. Install GitHub CLI.

   Windows:
   - Website: https://cli.github.com/
   - Or run this in PowerShell:
     winget install --id GitHub.cli

3. After installation finishes, close and reopen Cursor if needed.

4. Go back to the Cursor chat.

5. Run this command again:
   /github-helper
"@ | Write-Host
}

function Show-GhAuthMissingMessage {
@"
GitHub CLI is installed, but you are not logged in to GitHub yet.

What to do now:

1. Open PowerShell.
   - Click Start
   - Type: PowerShell
   - Open "Windows PowerShell" or "PowerShell"

2. In that PowerShell window, run this command exactly:
   gh auth login

3. Follow the prompts on screen.
   - GitHub may open a browser window
   - Sign in to your GitHub account
   - Approve the login if asked

4. When the login is complete, go back to Cursor.

5. In the Cursor chat, run this command again:
   /github-helper
"@ | Write-Host
}

function Ensure-Git {
    if (Get-Command git -ErrorAction SilentlyContinue) { return }
    Show-GitMissingMessage
    exit 1
}

function Ensure-Gh {
    if (Get-Command gh -ErrorAction SilentlyContinue) { return }
    Show-GhMissingMessage
    exit 1
}

function Ensure-GhAuth {
    gh auth status *> $null
    if ($LASTEXITCODE -eq 0) { return }
    Show-GhAuthMissingMessage
    exit 1
}

function Ensure-BranchExists {
    $branch = Get-CurrentBranch
    if (-not [string]::IsNullOrWhiteSpace($branch)) { return $branch }

    git show-ref --verify --quiet refs/heads/main *> $null
    if ($LASTEXITCODE -eq 0) {
        git checkout main *> $null
        return "main"
    }

    git checkout -b main *> $null
    return "main"
}

function Action-Status {
    $gitInstalled = if (Get-Command git -ErrorAction SilentlyContinue) { "y" } else { "n" }
    $ghInstalled = if (Get-Command gh -ErrorAction SilentlyContinue) { "y" } else { "n" }
    $ghLoggedIn = "n"
    $insideRepo = "n"
    $rootHere = "n"
    $remoteConfigured = "n"
    $remoteReachable = "n"
    $nextStep = ""

    if ($ghInstalled -eq "y") {
        gh auth status *> $null
        if ($LASTEXITCODE -eq 0) { $ghLoggedIn = "y" }
    }

    if ($gitInstalled -eq "y" -and (Is-GitRepo)) {
        $insideRepo = "y"
        if (At-RepoRoot) { $rootHere = "y" }
    }

    if ($insideRepo -eq "y" -and (Has-OriginRemote)) {
        $remoteConfigured = "y"
        if (Test-RemoteRepoReachable) { $remoteReachable = "y" }
    }

    if ($gitInstalled -eq "n") {
        $nextStep = "Install Git, then rerun /github-helper"
    } elseif ($ghInstalled -eq "n") {
        $nextStep = "Install GitHub CLI, then rerun /github-helper"
    } elseif ($ghLoggedIn -eq "n") {
        $nextStep = "Run gh auth login, then rerun /github-helper"
    } elseif ($insideRepo -eq "n") {
        $nextStep = "Run option 1 (Init repo) to initialize this folder locally and on GitHub"
    } elseif ($remoteConfigured -eq "n") {
        $nextStep = "Run option 1 (Init repo) to create and connect the private GitHub repo"
    } elseif ($remoteReachable -eq "n") {
        $nextStep = "Run option 1 (Init repo) to recreate or reconnect the GitHub repo"
    } else {
        $nextStep = "Repo is ready. Use option 2 (Push code) or option 3 (List branches) as needed"
    }

    Say "Status"
    Write-Host "Git installed: $gitInstalled"
    Write-Host "GitHub CLI installed: $ghInstalled"
    if ($ghInstalled -eq "y") {
        Write-Host "GitHub CLI logged in: $ghLoggedIn"
    }
    Write-Host "Inside git repo: $insideRepo"

    if ($insideRepo -eq "y") {
        Write-Host "At repo root: $rootHere"
        Write-Host "Current folder: $(Get-CurrentFolderName)"
        Write-Host "Repo root: $(Get-RepoRootName)"
        Write-Host "Current branch: $(Get-CurrentBranch)"
        Write-Host "GitHub remote configured: $remoteConfigured"
        if ($remoteConfigured -eq "y") {
            Write-Host "GitHub remote reachable: $remoteReachable"
            Write-Host "Origin URL: $(Get-OriginUrl)"
        }
        if (Has-Commits) {
            Write-Host "Latest commit: $(Get-LatestCommitShort)"
        } else {
            Write-Host "Latest commit: No commits yet"
        }
    }

    Write-Host "Recommended next step: $nextStep"

    if ($gitInstalled -eq "n") {
        Say ""
        Show-GitMissingMessage
    }
    if ($ghInstalled -eq "n") {
        Say ""
        Show-GhMissingMessage
    }
    if ($ghInstalled -eq "y" -and $ghLoggedIn -eq "n") {
        Say ""
        Show-GhAuthMissingMessage
    }
}

function Action-Init {
    Ensure-Git
    Ensure-Gh
    Ensure-GhAuth

    if (Is-GitRepo) {
        Info "Current folder is inside an existing Git repository."
        Info "Repo root: $(Get-RepoRoot)"
        Set-Location (Get-RepoRoot)
    } else {
        Info "Initializing Git repository with branch 'main'..."
        git init -b main *> $null
        if ($LASTEXITCODE -ne 0) {
            git init *> $null
            git checkout -b main *> $null
        }
        Info "Git repository initialized."
    }

    $repoName = if ($env:GITHUB_HELPER_REPO_NAME) { $env:GITHUB_HELPER_REPO_NAME } else { Default-RepoName }

    if (Has-OriginRemote) {
        if (Test-RemoteRepoReachable) {
            Info "GitHub remote is already connected and reachable."
        } else {
            Warn "Origin exists locally, but GitHub remote is unreachable."
            Warn "Reconnecting origin to a newly created private GitHub repo..."
            git remote remove origin
            gh repo create $repoName --private --source=. --remote=origin
            Info "GitHub repository created and remote reconnected."
        }
    } else {
        Info "Creating and connecting private GitHub repository..."
        gh repo create $repoName --private --source=. --remote=origin
        Info "GitHub repository created and remote connected."
    }

    git add .

    git diff --cached --quiet
    $hasStagedChanges = ($LASTEXITCODE -ne 0)

    if (-not $hasStagedChanges) {
        Warn "No changes to commit."
    } elseif (-not (Has-Commits)) {
        git commit -m (Initial-CommitMessage)
        Info "Initial commit created."
    } else {
        git commit -m (Default-CommitMessage)
        Info "Commit created."
    }

    $branch = Ensure-BranchExists

    if (Has-OriginRemote) {
        git push -u origin $branch
        Info "Pushed branch '$branch' to GitHub."
    } else {
        Err "GitHub remote is still not connected after init."
        exit 1
    }
}

function Action-Push {
    Ensure-Git

    if (-not (Is-GitRepo)) {
        Err "This folder is not a Git repository. Run option 1 (Init repo) first."
        exit 1
    }

    Set-Location (Get-RepoRoot)

    if (-not (Has-OriginRemote)) {
        Err "This repo is not connected to GitHub yet. Run option 1 (Init repo) first."
        exit 1
    }

    if (-not (Test-RemoteRepoReachable)) {
        Err "This repo has an origin configured locally, but the GitHub repo is unreachable or no longer exists."
        Err "Run option 1 (Init repo) first."
        exit 1
    }

    $branch = Ensure-BranchExists

    git add .

    git diff --cached --quiet
    $hasStagedChanges = ($LASTEXITCODE -ne 0)

    if (-not $hasStagedChanges) {
        Warn "No staged changes to commit."
    } else {
        git commit -m (Default-CommitMessage)
        Info "Commit created."
    }

    git push -u origin $branch
    Info "Pushed to origin/$branch"
}

function Action-Branches {
    Ensure-Git

    if (-not (Is-GitRepo)) {
        Err "This folder is not a Git repository."
        exit 1
    }

    Set-Location (Get-RepoRoot)

    Say "Current branch: $(Get-CurrentBranch)"
    Say "Local branches:"
    git branch --list

    if (Has-OriginRemote) {
        Say ""
        Say "Remote branches:"
        git branch -r
    }
}

function Action-Rollback {
    Ensure-Git

    if (-not (Is-GitRepo)) {
        Err "This folder is not a Git repository."
        exit 1
    }

    Set-Location (Get-RepoRoot)

    if (-not (Has-Commits)) {
        Err "There are no commits to roll back."
        exit 1
    }

    if ($env:GITHUB_HELPER_CONFIRM_ROLLBACK -ne "yes") {
        Err "Rollback requires explicit confirmation."
        Err "Run again with: `$env:GITHUB_HELPER_CONFIRM_ROLLBACK='yes'"
        exit 1
    }

    git reset --hard HEAD~1
    Info "Rolled back one commit."
}

function Show-Usage {
@"
Usage:
  .\.cursor\scripts\github-helper.ps1 init
  .\.cursor\scripts\github-helper.ps1 push
  .\.cursor\scripts\github-helper.ps1 branches
  .\.cursor\scripts\github-helper.ps1 rollback
  .\.cursor\scripts\github-helper.ps1 status

Optional environment variables:
  GITHUB_HELPER_REPO_NAME
  GITHUB_HELPER_COMMIT_MESSAGE
  GITHUB_HELPER_INITIAL_COMMIT_MESSAGE
  GITHUB_HELPER_CONFIRM_ROLLBACK=yes
"@ | Write-Host
}

switch ($Action.ToLowerInvariant()) {
    "init"     { Action-Init }
    "push"     { Action-Push }
    "branches" { Action-Branches }
    "rollback" { Action-Rollback }
    "status"   { Action-Status }
    default {
        Show-Usage
        exit 1
    }
}