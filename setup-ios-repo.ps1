# One-time setup: turns this folder into its own git repo and pushes it to GitHub so the
# ios-build.yml workflow can run there. Requires that you already created an EMPTY GitHub
# repository (no README, no .gitignore, no license) and have git configured with access to it.
#
# Usage:
#   powershell -File setup-ios-repo.ps1 -RemoteUrl "https://github.com/<you>/<repo>.git"

param(
    [Parameter(Mandatory=$true)]
    [string]$RemoteUrl
)

$ErrorActionPreference = "Stop"
$repoPath = "C:\Users\onkar\AndroidStudioProjects\VNSNews\BanarasBuzzIOS"

Set-Location $repoPath

# Move the workflow file into place. It was delivered outside .github/workflows because
# Claude's remote file tools refuse to write directly into that folder.
$workflowDir = Join-Path $repoPath ".github\workflows"
if (-not (Test-Path $workflowDir)) {
    New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
}
$stagedWorkflow = Join-Path $repoPath "ios-build.yml.tosave"
$finalWorkflow = Join-Path $workflowDir "ios-build.yml"
if (Test-Path $stagedWorkflow) {
    Move-Item -Path $stagedWorkflow -Destination $finalWorkflow -Force
    Write-Output "Moved ios-build.yml.tosave into .github/workflows/ios-build.yml"
} elseif (Test-Path $finalWorkflow) {
    Write-Output "Workflow file already in place."
} else {
    Write-Output "WARNING: could not find ios-build.yml.tosave or an existing .github/workflows/ios-build.yml"
}

if (-not (Test-Path (Join-Path $repoPath ".git"))) {
    git init
    git branch -M main
}

# Avoid "git remote remove origin" when it doesn't exist yet: under $ErrorActionPreference
# = Stop, PowerShell promotes that command's stderr message into a script-terminating error
# even with 2>$null, so check first instead of relying on redirection to silence it.
$existingRemotes = git remote
if ($existingRemotes -contains "origin") {
    git remote set-url origin $RemoteUrl
} else {
    git remote add origin $RemoteUrl
}

git add -A

$staged = git status --porcelain
if ([string]::IsNullOrWhiteSpace($staged)) {
    Write-Output "Nothing new to commit (already committed) - pushing existing history."
} else {
    git commit -m "Initial iOS SwiftUI port of Banaras Buzz"
}

git push -u origin main

Write-Output "Pushed to $RemoteUrl - check the Actions tab on GitHub for the iOS Build workflow run."
