# git-autosync.ps1 - DEBUGGED VERSION
$repoPath = "C:\Users\HUIWEI\rueditalie\rue-d-italie"
$gitEmail = "belljonathan50@gmail.com"
$gitName = "belljonathan50"

# 1. Configure Git
git config --global user.email $gitEmail
git config --global user.name $gitName

# 2. Enhanced Sync Function
function Sync-GitChanges {
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Checking for changes..." -ForegroundColor Cyan
    
    cd $repoPath
    Start-Sleep -Seconds 2  # Let file operations complete

    try {
        # Pull latest changes
        Write-Host "Pulling latest changes..." -ForegroundColor DarkGray
        $pullResult = git pull 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Pull failed: $pullResult" -ForegroundColor Red
            return
        }

        # Check for changes
        $changes = git status --porcelain
        if ($changes) {
            Write-Host "Detected changes:" -ForegroundColor Yellow
            $changes | ForEach-Object { Write-Host "  $_" }
            
            # Stage and commit
            git add --all
            $commitMsg = "Auto-sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            git commit -m $commitMsg
            
            # Push changes
            Write-Host "Pushing to GitHub..." -ForegroundColor DarkGray
            $pushResult = git push 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Successfully pushed changes!" -ForegroundColor Green
            } else {
                Write-Host "Push failed: $pushResult" -ForegroundColor Red
            }
        } else {
            Write-Host "No new changes detected." -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
}

# 3. Start File Watcher
Write-Host "`n=== GIT AUTO-SYNC ACTIVE ===" -ForegroundColor Magenta
Write-Host "Watching: $repoPath"
Write-Host "Git User: $gitName <$gitEmail>"
Write-Host "Press CTRL+C to stop`n" -ForegroundColor DarkGray

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $repoPath
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName
$watcher.EnableRaisingEvents = $true

# Register events with debouncing
$action = {
    Start-Sleep -Milliseconds 500  # Prevent duplicate triggers
    Sync-GitChanges
}

Register-ObjectEvent $watcher "Changed" -Action $action
Register-ObjectEvent $watcher "Created" -Action $action
Register-ObjectEvent $watcher "Renamed" -Action $action
Register-ObjectEvent $watcher "Deleted" -Action $action

# Keep running
try { while ($true) { Start-Sleep -Seconds 5 } }
finally {
    $watcher.Dispose()
    Write-Host "`nStopped file watcher." -ForegroundColor Yellow
}