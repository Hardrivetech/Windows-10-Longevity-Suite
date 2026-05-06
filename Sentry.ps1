<#
.SYNOPSIS
    Updates Microsoft Defender signatures and runs a malware scan.
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Sentry.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting Security Scan (Sentry)..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

try {
    # 1. Update Defender Signatures
    Write-Host "Updating virus definitions..."
    # 2. Run a Quick Scan
    # ScanType 1 = Quick Scan, 2 = Full Scan
    Write-Host "Running Quick Scan..."
    # 3. Check for active threats
    # Note: Get-MpThreat returns threats currently detected by the engine
    $Threats = Get-MpThreat
    if ($null -ne $Threats) {
        $ThreatCount = @($Threats).Count
        Write-Host "WARNING: Detected $ThreatCount threats!" -ForegroundColor Red
        
        for ($i = 0; $i -lt $ThreatCount; $i++) {
            $Threat = $Threats[$i]
            if ($null -ne $Threat) { Write-Host " - $($Threat.ThreatName) (Severity: $($Threat.SeverityID))" }
        }
    } else {
        Write-Host "No active threats detected." -ForegroundColor Green
    }

    if ($DryRun) {
        Write-Host "[DRY RUN] Would update MpSignature and start MpScan." -ForegroundColor Gray
    } else {
        Update-MpSignature
        Start-MpScan -ScanType QuickScan
    }
}
catch {
    Write-Error "An error occurred during the security scan: $_"
    Stop-Transcript; exit 1
}

Write-Host "Security scan complete." -ForegroundColor Green
Stop-Transcript