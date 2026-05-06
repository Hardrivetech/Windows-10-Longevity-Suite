<#
.SYNOPSIS
    Checks for available Windows and Driver updates. (Courier)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Courier.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Checking for Deliveries (Courier)..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"

try {
    # NASA Rule 7: Check return values for COM object creation
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    if ($null -eq $UpdateSession) { throw "NASA Rule 7: Failed to create Microsoft.Update.Session COM object." }
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    if ($null -eq $UpdateSearcher) { throw "NASA Rule 7: Failed to create UpdateSearcher COM object." }

    Write-Host "Searching for updates..."
    # NASA Rule 7: Check return values for search operation
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software' or IsInstalled=0 and Type='Driver'")

    $UpdatesFound = $SearchResult.Updates.Count

    if ($UpdatesFound -gt 0) {
        Write-Host "Found $UpdatesFound pending updates:" -ForegroundColor Yellow
        
        for ($i = 0; $i -lt $UpdatesFound; $i++) {
            $Update = $SearchResult.Updates.Item($i)
            if ($null -eq $Update) { continue }
            
            # NASA Rule 5: Assert Update.Categories is not null
            $Categories = if ($null -ne $Update.Categories) { ($Update.Categories | Select-Object -ExpandProperty Name) -join ", " } else { "Unknown" }
            # NASA Rule 5: Assert Update.Title is not null
            Write-Host " - [$($Categories)] $($Update.Title)"
        }
        
        Write-Host "`nPlease use Windows Settings to install these updates." -ForegroundColor Gray
    }
    else {
        Write-Host "Your system is up to date." -ForegroundColor Green
    }
}
catch {
    Write-Error "An error occurred during courier check: $_"
    Stop-Transcript; exit 1
}

Write-Host "Courier delivery check complete." -ForegroundColor Green
Stop-Transcript