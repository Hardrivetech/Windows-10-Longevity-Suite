<#
.SYNOPSIS
    Interactive setup, configuration, and uninstallation script for the Windows 10 Longevity Suite.
    Manages config.json, secure credentials, and the scheduled task.
#>

Set-StrictMode -Version Latest

$ScriptDir = $PSScriptRoot
$TaskName = "Windows Maintenance Suite"
$ConfigFile = Join-Path $ScriptDir "config.json"
$CredentialFile = Join-Path $ScriptDir "smtp.credential"

# --- Helper Functions ---
function Write-Header {
    Clear-Host
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "   Windows 10 Longevity Suite Setup            " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
}

function Test-AdminPrivileges {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as an Administrator."
        return $false
    }
    return $true
}

function Test-AllScriptsPresent {
    param (
        [string[]]$ScriptList
    )
    $AllPresent = $true
    foreach ($script in $ScriptList) {
        $path = Join-Path $ScriptDir $script
        if (-not (Test-Path $path)) {
            Write-Error "Missing required script: $path"
            $AllPresent = $false
        }
    }
    return $AllPresent
}

function Get-UserChoice {
    param (
        [string]$Prompt,
        [string[]]$Options
    )
    # NASA Rule 2: Give loops a fixed upper bound
    $MaxAttempts = 10
    for ($i = 0; $i -lt $MaxAttempts; $i++) {
        $choice = Read-Host "$Prompt ($($Options -join '/'))"
        if ($Options -contains $choice.ToLower()) {
            return $choice.ToLower()
        }
        Write-Warning "Invalid choice ($($i + 1)/$MaxAttempts)."
    }
    throw "User failed to provide valid input after $MaxAttempts attempts."
}

# NASA Rule 4: Break down large procedures into small, testable functions
function Initialize-DefaultConfig {
    return [PSCustomObject]@{
        DryRun = $false
        BackupDestination = "D:\Backups\SystemMaintenance"
        CPUThresholdPercent = 70
        MemoryThresholdMB = 500
        DiskSpaceThresholdPercent = 15
        FileRetentionDays = 30
        Email = [PSCustomObject]@{
            EnableEmailReport = $false
            SmtpServer = "smtp.yourprovider.com"
            SmtpPort = 587
            FromEmail = "maintenance@yourdomain.com"
            ToEmail = "your-admin-email@domain.com"
            EmailUser = "smtp-username"
        }
        Guard = [PSCustomObject]@{ StartupBlacklist = @("Microsoft Teams", "Cortana", "Spotify", "Steam", "Update") }
        Butler = [PSCustomObject]@{ 
            TargetFolders = @("%USERPROFILE%\\Downloads", "%USERPROFILE%\\Desktop")
            ExtensionMap = @{ 
                Documents = @(".pdf", ".docx", ".doc", ".txt", ".xlsx", ".pptx", ".csv")
                Images = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".svg")
                Videos = @(".mp4", ".mov", ".avi", ".mkv", ".wmv")
                Music = @(".mp3", ".wav", ".flac", ".aac")
                Archives = @(".zip", ".rar", ".7z", ".tar", ".gz")
                Applications = @(".exe", ".msi", ".bat")
            }
        }
        Master = [PSCustomObject]@{ EnableHeartbeat = $false; HeartbeatURL = ""; ScriptExecutionPriority = "Normal" }
    }
}

function Save-SuiteConfig {
    param($ConfigObject, $Path)
    # NASA Rule 5: Assert inputs
    if ($null -eq $ConfigObject) { throw "NASA Rule 5: Cannot save null configuration." }
    
    # NASA Rule 5: Assert path is valid
    Write-Host "`nSaving configuration to $Path..." -ForegroundColor Cyan
    $ConfigObject | ConvertTo-Json -Depth 5 | Set-Content $Path
    if (-not (Test-Path $Path)) { throw "NASA Rule 7: Failed to write config file." }
}

function Invoke-SetupFlow {
    param($Config)

    Write-Host "`n[0/7] Safety Configuration" -ForegroundColor Yellow
    $DryRunChoice = Get-UserChoice -Prompt "Enable Dry Run mode (No changes made)?" -Options @("y", "n")
    $Config.DryRun = ($DryRunChoice -eq 'y')

    Write-Host "`n[1/7] Backup Configuration" -ForegroundColor Yellow
    $BackupPath = Read-Host "Enter backup destination path (Default: $($Config.BackupDestination))"
    if (-not [string]::IsNullOrWhiteSpace($BackupPath)) { $Config.BackupDestination = $BackupPath }
    
    # NASA Rule 5/7: Verify the backup path is reachable and writable
    try {
        if (-not (Test-Path $Config.BackupDestination)) {
            Write-Warning "Warning: Backup path '$($Config.BackupDestination)' is currently unreachable. Ensure it exists before running maintenance."
        } elseif (-not (Test-Path $Config.BackupDestination -PathType Container)) {
            Write-Warning "Warning: Backup path '$($Config.BackupDestination)' is not a directory. Please provide a valid folder path."
        } else {
            # Attempt to create a temporary file to test write permissions
            $testFile = Join-Path $Config.BackupDestination "test_write_$(Get-Random).tmp"
            Set-Content -Path $testFile -Value "test" -ErrorAction Stop
            Remove-Item -Path $testFile -Force -ErrorAction Stop
            Write-Host "Backup path '$($Config.BackupDestination)' is reachable and writable." -ForegroundColor Green
        }
    } catch {
        Write-Warning "Error testing backup path '$($Config.BackupDestination)': $($_.Exception.Message). Please verify permissions."
    }

    # NASA Rule 5/7: Check System Restore status
    Write-Host "`nChecking System Restore Status..." -ForegroundColor Yellow
    $osDrive = (Get-Volume | Where-Object { $_.DriveLetter -eq 'C' }).DriveLetter
    $srStatus = Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $srStatus -or -not $srStatus) {
        Write-Warning "System Restore is currently DISABLED for drive '$osDrive'. Steward.ps1 will attempt to enable it, but manual verification is recommended."
        $EnableSR = Get-UserChoice -Prompt "Do you want to attempt to enable System Restore now? (Requires reboot for full effect)" -Options @("y", "n")
        if ($EnableSR -eq 'y') {
            try { Enable-ComputerRestore -Drive $osDrive -ErrorAction Stop; Write-Host "Attempted to enable System Restore. A reboot may be required." -ForegroundColor Green }
            catch { Write-Warning "Failed to enable System Restore: $($_.Exception.Message). Please enable it manually." }
        }
    }

    Write-Host "`n[2/7] Performance Thresholds" -ForegroundColor Yellow
    $CpuLimit = Read-Host "CPU Usage Alert Threshold % (Default: $($Config.CPUThresholdPercent))"
    if (-not [string]::IsNullOrWhiteSpace($CpuLimit) -and $CpuLimit -as [int]) { $Config.CPUThresholdPercent = [int]$CpuLimit }

    $MemLimit = Read-Host "Memory Usage Alert Threshold MB (Default: $($Config.MemoryThresholdMB))"
    if (-not [string]::IsNullOrWhiteSpace($MemLimit) -and $MemLimit -as [int]) { $Config.MemoryThresholdMB = [int]$MemLimit }

    $DiskLimit = Read-Host "Free Disk Space Alert Threshold % (Default: $($Config.DiskSpaceThresholdPercent))"
    if (-not [string]::IsNullOrWhiteSpace($DiskLimit) -and $DiskLimit -as [int]) { $Config.DiskSpaceThresholdPercent = [int]$DiskLimit }

    $Retention = Read-Host "Days to keep temporary files (Default: $($Config.FileRetentionDays))"
    if (-not [string]::IsNullOrWhiteSpace($Retention) -and $Retention -as [int]) { $Config.FileRetentionDays = [int]$Retention }

    return $Config
}

function Register-MaintenanceTask {
    param($ScriptDir, $TaskName, [bool]$DryRun)
    $Argument = "-NoProfile -File `"$ScriptDir\master.ps1`""
    if ($DryRun) { $Argument += " -DryRun" }
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $Argument
    $Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -TaskName $TaskName -Force | Out-Null
}

# --- Main Script Logic ---
if (-not (Test-AdminPrivileges)) { exit 1 }

Write-Header
Write-Host "This script will help you setup or uninstall the Windows 10 Longevity Suite." -ForegroundColor Gray

$ActionChoice = Get-UserChoice -Prompt "Choose an action" -Options @("setup", "uninstall")

try {
    if ($ActionChoice -eq "setup") {
        # Pre-flight check for all scripts
        $AllScripts = @(
            "Steward.ps1", "Janitor.ps1", "Vigilant.ps1", "Scrubber.ps1", "Guard.ps1",
            "Sentry.ps1", "Medic.ps1", "Inspector.ps1", "Surveyor.ps1", "Chiller.ps1",
            "Warden.ps1", "Ranger.ps1", "Tuner.ps1", "Butler.ps1", "Courier.ps1",
            "Archivist.ps1", "master.ps1"
        )
        if (-not (Test-AllScriptsPresent -ScriptList $AllScripts)) {
            Write-Error "Not all required scripts are present in $ScriptDir. Please ensure all .ps1 files are in this directory."
            exit 1
        }

        # Load existing config or create new
        $Config = Initialize-DefaultConfig
        if (Test-Path $ConfigFile) {
            Write-Host "Loading existing configuration from $ConfigFile..." -ForegroundColor Gray
            $LoadedConfig = Get-Content $ConfigFile | ConvertFrom-Json
            if ($null -ne $LoadedConfig) {
                # Merge loaded config into defaults. This ensures that even if the config file 
                # is missing properties, the object has them (required for PS 5.1).
                foreach ($prop in $LoadedConfig.PSObject.Properties) {
                    if ($prop.Value -is [System.Management.Automation.PSCustomObject] -and $null -ne $Config.$($prop.Name) -and $Config.$($prop.Name) -is [System.Management.Automation.PSCustomObject]) {
                        foreach ($subProp in $prop.Value.PSObject.Properties) {
                            $Config.$($prop.Name).$($subProp.Name) = $subProp.Value
                        }
                    } else {
                        $Config.$($prop.Name) = $prop.Value
                    }
                }
            }
        }

        # Modular Configuration Flow
        $Config = Invoke-SetupFlow -Config $Config

        # 3. Configure Email
        Write-Host "`n[3/7] Email Notifications" -ForegroundColor Yellow
        $EnableEmail = Get-UserChoice -Prompt "Enable Email Reports?" -Options @("y", "n")
        $Config.Email.EnableEmailReport = ($EnableEmail -eq 'y')

        if ($Config.Email.EnableEmailReport) {
            $Smtp = Read-Host "SMTP Server (Default: $($Config.Email.SmtpServer))"
            if (-not [string]::IsNullOrWhiteSpace($Smtp)) { $Config.Email.SmtpServer = $Smtp }
            
            $Port = Read-Host "SMTP Port (Default: $($Config.Email.SmtpPort))"
            if (-not [string]::IsNullOrWhiteSpace($Port) -and $Port -as [int]) { $Config.Email.SmtpPort = [int]$Port }

            $From = Read-Host "Sender Email Address (Default: $($Config.Email.FromEmail))"
            if (-not [string]::IsNullOrWhiteSpace($From) -and $From -like "*@*.*") { $Config.Email.FromEmail = $From }

            $To = Read-Host "Recipient Email Address (Default: $($Config.Email.ToEmail))"
            if (-not [string]::IsNullOrWhiteSpace($To) -and $To -like "*@*.*") { $Config.Email.ToEmail = $To }

            $User = Read-Host "SMTP Username (Default: $($Config.Email.EmailUser))"
            if (-not [string]::IsNullOrWhiteSpace($User)) { $Config.Email.EmailUser = $User }

            # NASA Rule 5/7: Verify SMTP server reachability
            Write-Host "`nChecking SMTP Server Reachability..." -ForegroundColor Yellow
            try {
                $testConnection = Test-NetConnection -ComputerName $Config.Email.SmtpServer -Port $Config.Email.SmtpPort -InformationLevel Detailed -ErrorAction Stop
                if ($testConnection.TcpTestSucceeded) {
                    Write-Host "SMTP server '$($Config.Email.SmtpServer):$($Config.Email.SmtpPort)' is reachable." -ForegroundColor Green
                } else {
                    Write-Warning "SMTP server '$($Config.Email.SmtpServer):$($Config.Email.SmtpPort)' is not reachable. Email reports may fail."
                }
            } catch {
                Write-Warning "Failed to test SMTP server reachability: $($_.Exception.Message). Email reports may fail."
            }

            # Securely store password
            Write-Host "Enter SMTP Password (will be encrypted):" -ForegroundColor Yellow
            $SmtpPass = Read-Host -AsSecureString
            $SmtpPass | ConvertFrom-SecureString | Set-Content $CredentialFile
            Write-Host "SMTP password saved securely to $CredentialFile." -ForegroundColor Green
        } elseif (Test-Path $CredentialFile) {
            Remove-Item $CredentialFile -Force
            Write-Host "Removed SMTP credential file." -ForegroundColor Green
        }

        # 4. Configure Guard
        Write-Host "`n[4/7] Startup Optimization (Guard)" -ForegroundColor Yellow
        Write-Host "Current Blacklist: $($Config.Guard.StartupBlacklist -join ', ')" -ForegroundColor Gray
        $BlacklistInput = Read-Host "Enter comma-separated app names to disable at startup (e.g., Teams,Spotify). Leave blank to keep current."
        if (-not [string]::IsNullOrWhiteSpace($BlacklistInput)) {
            $Config.Guard.StartupBlacklist = $BlacklistInput.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        }

        # 5. Configure Master
        Write-Host "`n[5/7] Master Orchestrator Settings" -ForegroundColor Yellow
        $EnableHeartbeat = Get-UserChoice -Prompt "Enable Heartbeat (sends a signal on completion)?" -Options @("y", "n")
        $Config.Master.EnableHeartbeat = ($EnableHeartbeat -eq 'y')
        if ($Config.Master.EnableHeartbeat) {
            $HeartbeatURL = Read-Host "Heartbeat URL (e.g., healthchecks.io endpoint)"
            if (-not [string]::IsNullOrWhiteSpace($HeartbeatURL) -and $HeartbeatURL -like "http*") { $Config.Master.HeartbeatURL = $HeartbeatURL }
        }
        
        # 6. Configure Butler
        Write-Host "`n[6/7] File Organization (Butler)" -ForegroundColor Yellow
        Write-Host "Current Target Folders: $($Config.Butler.TargetFolders -join ', ')" -ForegroundColor Gray
        $ButlerFoldersInput = Read-Host "Enter comma-separated folders to organize (e.g., %USERPROFILE%\Downloads,%USERPROFILE%\Desktop). Leave blank to keep current."
        if (-not [string]::IsNullOrWhiteSpace($ButlerFoldersInput)) { $Config.Butler.TargetFolders = $ButlerFoldersInput.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } }

        $Priority = Get-UserChoice -Prompt "Script Execution Priority (Lower priority means less impact on active use)" -Options @("BelowNormal", "Normal", "AboveNormal", "High")
        $Config.Master.ScriptExecutionPriority = $Priority
        
        # Save configuration to JSON
        Save-SuiteConfig -ConfigObject $Config -Path $ConfigFile

        Write-Host "`n[7/7] Registering Task Scheduler..." -ForegroundColor Yellow
        Register-MaintenanceTask -ScriptDir $ScriptDir -TaskName $TaskName -DryRun $Config.DryRun
        Write-Host "Task '$TaskName' registered for Sundays at 2:00 AM." -ForegroundColor Green

        Write-Host "`nSetup complete! Your Windows 10 Longevity Suite is ready." -ForegroundColor Cyan
        Write-Host "Location: $ScriptDir"
        Write-Host "Logs: $ScriptDir\Logs"
    }
    elseif ($ActionChoice -eq "uninstall") {
        Write-Host "`nUninstalling Windows 10 Longevity Suite..." -ForegroundColor Yellow

        # Remove Scheduled Task
        if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Host "Scheduled task '$TaskName' removed." -ForegroundColor Green
        } else {
            Write-Host "Scheduled task '$TaskName' not found." -ForegroundColor Gray
        }

        # Remove config and credential files
        if (Test-Path $ConfigFile) {
            Remove-Item $ConfigFile -Force
            Write-Host "Removed configuration file: $ConfigFile." -ForegroundColor Green
        }
        if (Test-Path $CredentialFile) {
            Remove-Item $CredentialFile -Force
            Write-Host "Removed SMTP credential file: $CredentialFile." -ForegroundColor Green
        }

        # Prompt to remove logs
        $RemoveLogs = Get-UserChoice -Prompt "Remove all generated logs in $ScriptDir\Logs?" -Options @("y", "n")
        if ($RemoveLogs -eq 'y') {
            if (Test-Path (Join-Path $ScriptDir "Logs")) {
                Remove-Item (Join-Path $ScriptDir "Logs") -Recurse -Force
                Write-Host "Removed logs directory." -ForegroundColor Green
            } else {
                Write-Host "Logs directory not found." -ForegroundColor Gray
            }
        }

        # Prompt to remove all scripts
        $RemoveScripts = Get-UserChoice -Prompt "Remove all PowerShell scripts in $ScriptDir?" -Options @("y", "n")
        if ($RemoveScripts -eq 'y') {
            Get-ChildItem -Path $ScriptDir -Filter "*.ps1" | ForEach-Object {
                Remove-Item $_.FullName -Force
            }
            # Also remove config.json if it wasn't removed above (e.g. if user said no to logs)
            if (Test-Path $ConfigFile) { Remove-Item $ConfigFile -Force }
            if (Test-Path $CredentialFile) { Remove-Item $CredentialFile -Force }
            Write-Host "Removed all PowerShell scripts from $ScriptDir." -ForegroundColor Green
        }

        Write-Host "`nUninstall complete. The Windows 10 Longevity Suite has been removed." -ForegroundColor Cyan
    }
}
catch {
    Write-Error "An error occurred during setup: $_"
}