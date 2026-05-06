# Windows 10 Longevity Suite

A comprehensive collection of PowerShell scripts designed to automate system maintenance, improve performance, and ensure the long-term health of Windows 10 installations. This suite targets "system rot" by managing temp files, integrity checks, security, and data backups.

## 🚀 Features & Script Overview

### Modular Maintenance
Each script is standalone, allowing for targeted execution.
### Disk Health Alerts
Receive Windows Toast notifications if potential disk failures are detected.
### Consolidated Reporting
The `Master.ps1` orchestrator provides a final summary table of all task statuses.

The suite consists of several modular scripts that can be run individually or orchestrated via the `Master.ps1` entry point.

| Script | Function |
| :--- | :--- |
| **Steward.ps1** | Creates a System Restore Point as a safety net before maintenance begins. |
| **Janitor.ps1** | Cleans system temp files, Windows Update cache, and runs Disk Cleanup. |
| **Vigilant.ps1** | Purges files and logs older than a defined threshold (e.g., 30 days). |
| **Scrubber.ps1** | Clears caches for Google Chrome, Microsoft Edge, and Mozilla Firefox. |
| **Guard.ps1** | Disables unnecessary startup applications and bloatware scheduled tasks. |
| **Sentry.ps1** | Updates Microsoft Defender signatures and performs a Quick Malware Scan. |
| **Medic.ps1** | Runs DISM and SFC to verify and repair system file integrity. |
| **Inspector.ps1** | Monitors S.M.A.R.T. status and physical disk health metrics. |
| **Custodian.ps1** | Cleans up the Windows Component Store (WinSxS) to free up disk space. |
| **Surveyor.ps1** | Checks all fixed drives for free space below a defined threshold. |
| **Chiller.ps1** | Checks CPU temperatures and detects active thermal throttling. |
| **Warden.ps1** | Identifies and logs processes consuming excessive RAM. |
| **Ranger.ps1** | Identifies and logs processes consuming excessive CPU. |
| **Tuner.ps1** | Performs TRIM optimization for SSDs or defragmentation for HDDs. |
| **Butler.ps1** | Automatically sorts files in Downloads/Desktop into category folders. |
| **Courier.ps1** | Checks for pending Windows and Driver updates. |
| **Archivist.ps1** | Uses `Robocopy` to mirror critical user folders to a secure destination. |
| **Master.ps1** | **The Orchestrator.** Runs all scripts in the optimal logical sequence. |

## 🛠️ Setup & Configuration

The recommended way to set up and configure the suite is using the interactive `Setup.ps1` script.

### Automated Setup (Recommended)

1. Place all scripts in `C:\Scripts`.
2. Open PowerShell as an **Administrator**.
3. Run the setup script:
   ```powershell
   cd C:\Scripts
   .\Setup.ps1 -ExecutionPolicy Bypass
   ```
   This script will interactively guide you through configuring paths, thresholds, and email settings. It will also register the task in Windows Task Scheduler automatically.
   - **Configuration:** All settings will be stored in `C:\Scripts\config.json`.
   - **Secure Credentials:** SMTP passwords will be encrypted and stored in `C:\Scripts\smtp.credential`.

### Configuration Details
All configurable parameters are stored in `C:\Scripts\config.json`. This file is managed by `Setup.ps1`.

### Uninstalling the Suite

To remove the scheduled task, configuration, and optionally the scripts and logs:

1. Open PowerShell as an **Administrator**.
2. Run the setup script with the uninstall option:
   ```powershell
   cd C:\Scripts
   .\Setup.ps1
   ```
   When prompted, choose `uninstall`.

### 🔒 Security & Code Signing
To protect against unauthorized script modifications, it is recommended to sign the suite:
1. Run `.\Sign-Scripts.ps1` as an Administrator.
2. Set your system execution policy: `Set-ExecutionPolicy AllSigned`.
3. Update your Scheduled Task to remove the `-ExecutionPolicy Bypass` argument.

### Manual Setup (Advanced Users)
Refer to the `config.json` file for all configurable parameters. You can edit this file directly or use `Setup.ps1` to guide you.

To manually create the `smtp.credential` file (if not using `Setup.ps1`):
```powershell
Read-Host -AsSecureString | ConvertFrom-SecureString | Set-Content C:\Scripts\smtp.credential
```

To manually schedule the task, follow the instructions below.

## 📅 Automation with Task Scheduler

To get the most out of this suite, it should be automated via the Windows Task Scheduler.

1. Open **Task Scheduler** and click **Create Task**.
2. **General Tab:** 
   - Name: `Windows Maintenance Suite`
   - Check **Run with highest privileges** (Required for system repairs and restore points).
3. **Triggers Tab:** 
   - Add a trigger (e.g., Weekly on Sundays at 2:00 AM).
4. **Settings Tab (for Toast Notifications):**
   - For toast notifications to appear, ensure the task is configured to **"Run only when user is logged on"**.
4. **Actions Tab:** 
   - Action: `Start a program`
   - Program/script: `powershell.exe`
   - Add arguments: `-ExecutionPolicy Bypass -File "C:\Scripts\Master.ps1"`

## 📊 Logging

Each execution generates detailed logs located in `C:\Scripts\Logs\`. 
- Use `Master.log` for a high-level overview of the suite execution.
- Individual logs (e.g., `Sentry.log`, `Backup.log`) provide granular details on specific tasks.

## ⚠️ Requirements

- **OS:** Windows 10 (Some scripts may work on Windows 11).
- **Permissions:** Must be run as an **Administrator**.
- **Execution Policy:** Scripts require the `Bypass` policy to run via automation.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

**Disclaimer:** This project is intended for personal use. Use at your own risk. Always ensure you have a verified backup before running system-wide cleanup utilities.