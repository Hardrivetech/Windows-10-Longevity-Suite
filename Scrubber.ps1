<#
.SYNOPSIS
    Clears cache for Google Chrome, Microsoft Edge, and Mozilla Firefox. (Scrubber)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Scrubber.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append
Write-Host "Data Scouring (Scrubber): Cleaning Browser Caches..." -ForegroundColor Cyan

try {
    # Chromium-based browsers (Chrome/Edge)
    $Browsers = @(
        @{ Name = "Chrome"; Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" },
        @{ Name = "Edge";   Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache" }
    )

    # NASA Rule 2: Use bounded for-loops for collection iteration
    for ($i = 0; $i -lt $Browsers.Count; $i++) {
        $Browser = $Browsers[$i]
        # NASA Rule 5: Assert Browser.Path is not null
        if ($null -ne $Browser.Path) {
            if (Test-Path $Browser.Path) {
                Write-Host "Cleaning $($Browser.Name)..." -ForegroundColor Yellow
                # NASA Rule 7: Check return values
                Remove-Item -Path "$($Browser.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Firefox (dynamic profile search)
    $FFPath = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $FFPath) {
        # NASA Rule 7: Check return values
        $FFProfiles = Get-ChildItem -Path $FFPath -Directory -ErrorAction SilentlyContinue
        if ($null -ne $FFProfiles) {
            Write-Host "Cleaning Firefox profiles..." -ForegroundColor Yellow
            foreach ($FFProfile in $FFProfiles) {
                $CachePath = Join-Path $FFProfile.FullName "cache2"
                if (Test-Path $CachePath) {
                    # NASA Rule 7: Check return values
                    Remove-Item -Path "$CachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
catch {
    Write-Error "An error occurred during scouring: $_"
    Stop-Transcript; exit 1
}

Write-Host "Scouring complete." -ForegroundColor Green
Stop-Transcript