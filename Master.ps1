<#
.SYNOPSIS
    Master Orchestrator for the Windows 10 Longevity Suite.
    Executes all maintenance scripts in a predefined, logical order.
#>

Set-StrictMode -Version Latest

$ScriptDir = $PSScriptRoot
$LogPath = "$ScriptDir\Logs\Master.log"

# Ensure Administrative Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Master Orchestrator must be run as an Administrator."
    exit 1
}

# Ensure log directory exists
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) -ItemType Directory }

Start-Transcript -Path $LogPath -Append

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   WINDOWS 10 LONGEVITY SUITE - MASTER START   " -ForegroundColor Cyan
Write-Host "   Started at: $(Get-Date)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# --- CONFIGURATION LOADING ---
$ConfigFile = Join-Path $ScriptDir "config.json"
$CredentialFile = Join-Path $ScriptDir "smtp.credential"

if (-not (Test-Path $ConfigFile)) {
    # NASA Rule 5: Assert configuration file existence
    Write-Error "NASA Rule 5: Configuration file not found: $ConfigFile. Please run Setup.ps1."
    Write-Host "Please run Setup.ps1 to configure the suite." -ForegroundColor Yellow
    Stop-Transcript
    exit 1
}

$Config = Get-Content $ConfigFile | ConvertFrom-Json

# Extract email settings
# NASA Rule 5: Assert configuration is valid against schema
. (Join-Path $ScriptDir "Get-SuiteConfigSchema.ps1") # Dot-source the schema definition

Test-ConfigSchema -ConfigToValidate $Config -ExpectedSchema (Get-SuiteConfigSchema)

if ($null -eq $Config.Email) {
    throw "NASA Rule 5: Email configuration section missing from config.json."
}
$EnableEmailReport = $Config.Email.EnableEmailReport
$UseSSL     = $true # Hardcoded for security best practice
$DryRun     = $Config.DryRun

# Function to send a Windows Toast Notification
function Send-ToastNotification {
    param (
        [string]$Title,
        [string]$Message,
        [string]$AppId = "PowerShell.MaintenanceSuite" # Custom AppId for your suite
    )

    try {
        # Load the Windows.UI.Notifications assembly
        Add-Type -AssemblyName System.Runtime.WindowsRuntime
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        # Create the XML for the toast notification
        $template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02
        $xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent($template)

        $textNodes = $xml.GetElementsByTagName("text")
        $textNodes.Item(0).AppendChild($xml.CreateTextNode($Title)) | Out-Null
        $textNodes.Item(1).AppendChild($xml.CreateTextNode($Message)) | Out-Null

        # Create the toast notification
        $toast = [Windows.UI.Notifications.ToastNotification]::New($xml)
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId)
        $notifier.Show($toast)
        Write-Host "Toast notification sent: '$Title' - '$Message'" -ForegroundColor DarkGreen
    }
    catch {
        Write-Warning "Could not send toast notification: $($_.Exception.Message). Ensure the task runs in an interactive user session."
    }
}

# Function to send a heartbeat signal
function Send-Heartbeat {
    param (
        [string]$Url
    )
    if (-not [string]::IsNullOrWhiteSpace($Url)) {
        try {
            # NASA Rule 5: Assert URL is valid before sending
            if (-not ($Url -as [uri])) { throw "NASA Rule 5: Invalid Heartbeat URL format." }
            Write-Host "Sending heartbeat to $Url..." -ForegroundColor DarkGray
            # Use Invoke-WebRequest for a simple GET request
            # -UseBasicParsing is for compatibility and speed
            Invoke-WebRequest -Uri $Url -Method Get -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop | Out-Null
            Write-Host "Heartbeat sent successfully." -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to send heartbeat: $($_.Exception.Message)"
        }
    } else {
        Write-Host "Heartbeat URL not configured. Skipping heartbeat." -ForegroundColor Gray
    }
}

# Function to validate the loaded configuration against a schema
function Test-ConfigSchema {
    param (
        [PSCustomObject]$ConfigToValidate,
        [PSCustomObject]$ExpectedSchema
    )
    # NASA Rule 5: Assert inputs
    if ($null -eq $ConfigToValidate) { throw "NASA Rule 5: ConfigToValidate is null." }
    if ($null -eq $ExpectedSchema) { throw "NASA Rule 5: ExpectedSchema is null." }

    $IsValid = $true
    $Errors = New-Object 'System.Collections.Generic.List[string]'

    # NASA Rule 2: Use bounded for-loop for property iteration
    $ExpectedProperties = @($ExpectedSchema.PSObject.Properties)
    for ($i = 0; $i -lt $ExpectedProperties.Count; $i++) {
        $Prop = $ExpectedProperties[$i]
        $PropName = $Prop.Name
        $ExpectedType = $Prop.Value.GetType()

        if (-not $ConfigToValidate.PSObject.Properties.Contains($PropName)) {
            $Errors.Add("Missing property: '$PropName'")
            $IsValid = $false
            continue
        }

        $ActualValue = $ConfigToValidate.$PropName
        $ActualType = $ActualValue.GetType()

        # Basic type checking (can be extended for deeper validation)
        if ($ExpectedType -eq [PSCustomObject]) {
            # Recursively validate nested objects
            # NASA Rule 5: Assert recursive call is valid
            if (-not (Test-ConfigSchema -ConfigToValidate $ActualValue -ExpectedSchema $Prop.Value)) {
                $Errors.Add("Nested object '$PropName' failed validation.")
                $IsValid = $false
            }
        } elseif ($ExpectedType -eq [System.Object[]]) { # Array type
            if (-not ($ActualType -is [System.Array])) {
                $Errors.Add("Property '$PropName' expected type Array, got '$ActualType'.")
                $IsValid = $false
            }
        } elseif ($ActualType -ne $ExpectedType -and $ActualType -ne [System.Management.Automation.PSCustomObject]) {
            $Errors.Add("Property '$PropName' expected type '$ExpectedType', got '$ActualType'.")
            $IsValid = $false
        }
    }
    if (-not $IsValid) { throw "NASA Rule 5: Configuration schema validation failed: $($Errors -join '; ')" }
    return $true
}

# NASA Rule 4: Extract complex reporting to a discrete function
function Invoke-SuiteReporting {
    param(
        [Parameter(Mandatory=$true)]$Results,
        [Parameter(Mandatory=$true)]$EnableEmail,
        [Parameter(Mandatory=$true)]$Attachments,
        [Parameter(Mandatory=$true)][string]$SmtpAuthPath,
        [Parameter(Mandatory=$true)]$SmtpConfig,
        [bool]$UseSsl = $true
    )

    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "   SUMMARY REPORT                              " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    $Results | Format-Table -AutoSize

    if ($EnableEmail) {
        Write-Host "`nSending Email Report..." -ForegroundColor Cyan
        try {
            $Header = "<style>table{border-collapse:collapse;width:100%;font-family:Arial;}th,td{border:1px solid #ddd;padding:8px;text-align:left;}th{background-color:#008B8B;color:white;}</style>"
            $HtmlBody = $Results | ConvertTo-Html -Head $Header -PreContent "<h2>Maintenance Summary: $(hostname)</h2><p>Execution Date: $(Get-Date)</p>"
            
            $Creds = $null
            if (Test-Path $SmtpAuthPath) {
                $SecurePass = Get-Content $SmtpAuthPath | ConvertTo-SecureString
                $Creds = New-Object System.Management.Automation.PSCredential($SmtpConfig.EmailUser, $SecurePass)
            }

            $MailParams = @{
                SmtpServer  = $SmtpConfig.SmtpServer
                Port        = $SmtpConfig.SmtpPort
                From        = $SmtpConfig.FromEmail
                To          = $SmtpConfig.ToEmail
                Subject     = "Windows Maintenance Report - $(hostname) - $(Get-Date -Format 'yyyy-MM-dd')"
                Body        = $HtmlBody | Out-String
                BodyAsHtml  = $true
                Credential  = $Creds
                Attachments = $Attachments
                UseSsl      = $UseSsl
                ErrorAction = "Stop"
            }
            Send-MailMessage @MailParams
            Write-Host "Email report sent successfully." -ForegroundColor Green
        }
        catch { Write-Error "Failed to send email report: $_" }
    }
}

# The logical order of execution for maximum safety and efficiency
$MaintenanceScripts = @(
    "Steward.ps1",        # 1. Create safety net before changes
    "Janitor.ps1",        # 2. System cleanup
    "Vigilant.ps1",       # 3. File retention (Purge old files)
    "Scrubber.ps1",       # 3. Browser cache cleanup
    "Guard.ps1",          # 4. Optimize startup apps
    "Sentry.ps1",         # 5. Security/Malware scan
    "Medic.ps1",          # 6. System integrity (SFC/DISM)
    "Inspector.ps1",      # 7. Monitor S.M.A.R.T. status
    "Custodian.ps1",      # 8. Windows Component Store cleanup
    "Surveyor.ps1",       # 8. Check for low disk space
    "Chiller.ps1",        # 9. Monitor temperature and throttling
    "Warden.ps1",         # 10. Check for high memory usage processes
    "Ranger.ps1",         # 11. Check for high CPU usage processes
    "Tuner.ps1",          # 11. Drive optimization (TRIM/Defrag)
    "Butler.ps1",         # 12. File organization
    "Courier.ps1",        # 13. Check for Windows/Driver updates
    "Archivist.ps1"       # 14. Final backup of cleaned system
)

# NASA Rule 3 & 5: Pre-allocate memory and Assert creation
$TaskCount = $MaintenanceScripts.Count
if ($TaskCount -le 0) { throw "NASA Rule 5: Maintenance script list is empty." }

$TaskResults = New-Object 'System.Collections.Generic.List[PSCustomObject]'
$AttachmentPaths = New-Object 'System.Collections.Generic.List[string]'

# NASA Rule 5: Assert Environment Readiness
if ($null -ne $Config.BackupDestination -and -not (Test-Path $Config.BackupDestination)) {
    Write-Warning "NASA Rule 5: Backup Destination is unreachable. Archivist task will likely fail."
}

if ($null -eq $TaskResults -or $null -eq $AttachmentPaths) { throw "NASA Rule 5: Memory allocation failed." }

# NASA Rule 2: Use bounded for-loops instead of foreach
for ($i = 0; $i -lt $TaskCount; $i++) {
    $Script = $MaintenanceScripts[$i]
    $FullPath = Join-Path $ScriptDir $Script
    
    if (Test-Path $FullPath) {
        Write-Host "`n[TASK] Executing $Script..." -ForegroundColor White -BackgroundColor DarkCyan
        
        # Determine the log path for the current script and add it to attachments *before* execution
        $ScriptLogFileName = $Script -replace '\.ps1$', '.log' # e.g., Janitor.ps1 -> Janitor.log
        $AttachmentPaths.Add((Join-Path (Join-Path $ScriptDir "Logs") $ScriptLogFileName))

        $TaskTimer = [System.Diagnostics.Stopwatch]::StartNew()
        
        # If scripts are signed, we remove '-ExecutionPolicy Bypass' to allow system policy to govern execution.
        # This supports the 'AllSigned' recommendation in the README.
        $ExecutionArgs = "-NoProfile -File `"$FullPath`""
        
        if ($DryRun) {
            $ExecutionArgs += " -DryRun" # Pass DryRun flag to sub-scripts
        }

        $Process = Start-Process powershell.exe -ArgumentList $ExecutionArgs -Wait -PassThru -NoNewWindow -WindowStyle Hidden -Priority $Config.Master.ScriptExecutionPriority
        $TaskTimer.Stop()
        
        # NASA Rule 7: Check return values
        if ($null -eq $Process) { throw "Failed to initialize process for $Script" }

        $Status = if ($Process.ExitCode -eq 0) { "Success" } else { "Failed" }
        $Duration = "$([math]::Round($TaskTimer.Elapsed.TotalSeconds, 2))s"
        $Result = [PSCustomObject]@{ Task = $Script; Status = $Status; Duration = $Duration }
        $TaskResults.Add($Result)

        # Check specifically for Inspector.ps1 failure to send a toast notification
        if ($Script -eq "Inspector.ps1" -and $Status -eq "Failed") {
            Send-ToastNotification -Title "Disk Health Alert!" -Message "Disk issues detected during maintenance. Check logs for details."
        }

        # Check for Thermal issues
        if ($Script -eq "Chiller.ps1" -and $Status -eq "Failed") {
            Send-ToastNotification -Title "Thermal Alert!" -Message "System is overheating or throttling. Check fans and airflow."
        }

        # Check for High Memory Processes issues
        if ($Script -eq "Warden.ps1" -and $Status -eq "Failed") {
            Send-ToastNotification -Title "High Memory Usage Alert!" -Message "Processes consuming excessive memory detected. Check logs for details."
        }

        # Check for High CPU Processes issues
        if ($Script -eq "Ranger.ps1" -and $Status -eq "Failed") {
            Send-ToastNotification -Title "High CPU Usage Alert!" -Message "Processes consuming excessive CPU detected. Check logs for details."
        }

        # Check for Low Disk Space issues
        if ($Script -eq "Surveyor.ps1" -and $Status -eq "Failed") {
            Send-ToastNotification -Title "Low Disk Space Alert!" -Message "One or more drives are running out of space. Check logs for details."
        }
    } else {
        Write-Warning "[MISSING] Script not found: $FullPath"
        $MissingResult = [PSCustomObject]@{ Task = $Script; Status = "Missing"; Duration = "0s" }
        $TaskResults.Add($MissingResult)
    }
}

# --- POST-EXECUTION HEARTBEAT ---
if ($Config.Master.EnableHeartbeat) {
    Send-Heartbeat -Url $Config.Master.HeartbeatURL
}

Invoke-SuiteReporting -Results $TaskResults -EnableEmail $EnableEmailReport -Attachments $AttachmentPaths -SmtpAuthPath $CredentialFile -SmtpConfig $Config.Email -UseSsl $UseSSL

Write-Host "`nMaster Orchestration Finished at: $(Get-Date)" -ForegroundColor Gray
Stop-Transcript
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUv8w9qRllkJTL+xP66CPpL3u4
# LEqgggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
# AQsFADAiMSAwHgYDVQQDDBdXaW5kb3dzTWFpbnRlbmFuY2VTdWl0ZTAeFw0yNjA1
# MDgyMTAxMjNaFw0yNzA1MDgyMTIxMjNaMCIxIDAeBgNVBAMMF1dpbmRvd3NNYWlu
# dGVuYW5jZVN1aXRlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3/92
# wnIIt1llLFV+0SjNEzyfmSk2LRqCY0G+SI1SRoBlPy4HXmQw9MGBFV4t2BoM202A
# cfNL8TTzhHblkwoUYpOEP4/NpWFdMFeQ+ord/qP2AcXvEChI2yOQXM7BGcyOfeOv
# UE8I9UgHVXdECumzfGwgwWPheypDu8faj4G8YhMv/OgaofxtxWEDjVGLcjruSYQ0
# gekSLdIqhi4X8lCroO5J6/4ZoO94UH8tgSfN6BS2GYwCLaOfrhhDiSvuOCl7X0x2
# 5yxvpMPAzrwI4OMMj5gyZaseXhcQ1Mi5lBTyjpIiaeEtiwBpFPOSIgMYcfTEGFUy
# pwkmw1q0SQbn5lOaFQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAww
# CgYIKwYBBQUHAwMwHQYDVR0OBBYEFJwEMfRj/lYgIdengr8i4zW0cFZqMA0GCSqG
# SIb3DQEBCwUAA4IBAQBM0i2BcZ6KmpbZv0ksmLj6QQ4qVLVh2P9pRcK2C8xz8EZ2
# jK1BWPSyPar5CqLw2ZNubAEAZxbFQlCxmWEgzjZ3QybsxLDmHv4uhljvU2nWnnty
# rze/8DJiSp9fiA4xu/H4W36dSJcvYfAisAxBJKV/fzIbHNrQWRCvzySygTyGjRb2
# x7li8UsU+fZAYDnWp5aU9Gw+sTj5ULK/wcvBsKD9y2sN6az/Z4S4xHj3LpmQfDrX
# VYBPP+WnLhwLEqYqq/ZSVvYsWPa/ZzSJMBsIiI+fC/IhHGWNX9/xzFfkGm9xpd9s
# epWLjCEpVE+R3Q85JLVNwYO1MCobYe+Mm8tRAwL9MYIB1zCCAdMCAQEwNjAiMSAw
# HgYDVQQDDBdXaW5kb3dzTWFpbnRlbmFuY2VTdWl0ZQIQMl3zoiC4cYFCMb3KCL1b
# 9jAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG
# 9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIB
# FTAjBgkqhkiG9w0BCQQxFgQUqpJInzbsOSm71nPQUv6iE9pWV3AwDQYJKoZIhvcN
# AQEBBQAEggEAAfS4mMd0esay7j/wIbtvlrJLDlhbYQeSbZSSGVPpPziEPCVnLUPi
# vhUfxQLwtZ7Ht0n7zpcFbG1p1YIWJgKAVRvUy9ZeJo1ymE5pLPK488Xiv9mL/Xyj
# iidwNaj1meMPhkj+dIT7zCT+5ikZbvCvZ9a798JlU3geJeTa/Z65VzGI/UxXv6vx
# BOHKf/Os74j+pXc8zAsB5i6h8ELtsChaonrcsC0HYeGVeeIgi+gFSEIz/etlNoyt
# sPz/ph33cCtUQXovm2jf2qua9xvOFbnkSw/p6g6HBwrcpJBcc4Xuxe14ynW/kP9u
# 5yXqUCZcdEpUKBP9loIwJiZeb/7zjsl0ew==
# SIG # End signature block
