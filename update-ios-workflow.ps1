# Updates the iOS Build workflow to fix the Xcode project-format error and pushes it.
#
# Usage:
#   powershell -File update-ios-workflow.ps1

$ErrorActionPreference = "Stop"
$repoPath = "C:\Users\onkar\AndroidStudioProjects\VNSNews\BanarasBuzzIOS"

Set-Location $repoPath

$stagedWorkflow = Join-Path $repoPath "ios-build-fix.yml.tosave"
$finalWorkflow = Join-Path $repoPath ".github\workflows\ios-build.yml"

if (-not (Test-Path $stagedWorkflow)) {
    Write-Output "ERROR: could not find ios-build-fix.yml.tosave in $repoPath"
    exit 1
}

Copy-Item -Path $stagedWorkflow -Destination $finalWorkflow -Force
Write-Output "Updated .github/workflows/ios-build.yml"

git add -A

$staged = git status --porcelain
if ([string]::IsNullOrWhiteSpace($staged)) {
    Write-Output "Nothing changed - workflow already up to date."
} else {
    git commit -m "Fix Xcode version selection in CI to resolve project format error"
    git push origin main
    Write-Output "Pushed fix - check the Actions tab on GitHub for the new iOS Build run."
}
