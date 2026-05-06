<#
.SYNOPSIS
    Self-signs all scripts in the suite to allow for an AllSigned execution policy.
#>

Set-StrictMode -Version Latest

$CertSubject = "CN=WindowsMaintenanceSuite"
$Cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -eq $CertSubject } | Select-Object -First 1

if (-not $Cert) {
    Write-Host "Creating self-signed code signing certificate..." -ForegroundColor Cyan
    $Cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject $CertSubject -KeyUsage DigitalSignature -FriendlyName "Maintenance Suite Signer"
    
    # Export and Import to Trusted Root to avoid 'Unknown Publisher' warnings
    $Path = Join-Path $env:TEMP "MaintenanceSuite.cer"
    Export-Certificate -Cert $Cert -FilePath $Path | Out-Null
    Import-Certificate -FilePath $Path -CertStoreLocation Cert:\CurrentUser\Root | Out-Null
    Remove-Item $Path
}

Write-Host "Signing scripts in $PSScriptRoot..." -ForegroundColor Yellow

$Scripts = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1"
foreach ($Script in $Scripts) {
    if ($Script.Name -ne "Sign-Scripts.ps1") {
        Write-Host " Signing $($Script.Name)..."
        Set-AuthenticodeSignature -FilePath $Script.FullName -Certificate $Cert | Out-Null
    }
}

Write-Host "`nAll scripts signed." -ForegroundColor Green
Write-Host "You can now set your execution policy to AllSigned:" -ForegroundColor Gray
Write-Host "Set-ExecutionPolicy AllSigned -Scope LocalMachine" -ForegroundColor White