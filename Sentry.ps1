<#
.SYNOPSIS
    Updates Microsoft Defender signatures and runs a malware scan.
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Sentry.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting Security Scan (Sentry)..." -ForegroundColor Cyan

try {
    # 1. Update Defender Signatures
    Write-Host "Updating virus definitions..."
    Update-MpSignature

    # 2. Run a Quick Scan
    # ScanType 1 = Quick Scan, 2 = Full Scan
    Write-Host "Running Quick Scan..."
    Start-MpScan -ScanType QuickScan

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
}
catch {
    Write-Error "An error occurred during the security scan: $_"
    Stop-Transcript; exit 1
}

Write-Host "Security scan complete." -ForegroundColor Green
Stop-Transcript