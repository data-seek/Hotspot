# WiFi Hotspot Auto-Setup Script (Main Script)
# Supports PowerShell 5.0+ including Windows PowerShell 5.1 and PowerShell 7.x
# Version: 1.0.0

# Set encoding to fix display issues
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Check PowerShell version
$PSVersion = $PSVersionTable.PSVersion.Major
if ($PSVersion -lt 5) {
    Write-Host "Error: This script requires PowerShell 5.0 or later." -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    exit 1
}

# Script information
$ScriptInfo = @{
    Name = "WiFi Hotspot Auto-Setup"
    Version = "1.0.0"
    MinPSVersion = "5.0"
    Author = "WiFi Hotspot Tool"
    Description = "Automatically sets up WiFi hotspot with system startup task"
    UpdateURL = "https://get.data-seek.cn/hotspot-main.ps1"
}

# Version-specific features
$IsPowerShell7 = $PSVersion -ge 7
$IsWindowsPowerShell = $PSVersionTable.PSEdition -eq "Desktop"

Write-Host @"
WiFi Hotspot Auto-Setup Script v$($ScriptInfo.Version)
============================================
PowerShell Version: $($PSVersionTable.PSVersion) $(if ($IsPowerShell7) { "(Core)" } else { "(Desktop)" })
Administrator: YES
Mode: LIVE MODE
"@ -ForegroundColor Green

# Security warning and confirmation
Write-Host @"
============================================
SECURITY WARNING
============================================
This script will:
- Modify system execution policies
- Create scheduled tasks with SYSTEM privileges
- Enable Windows WiFi hotspot
- Start and configure network services

Only run this script if you trust the source!
Source: $($ScriptInfo.UpdateURL)

Press Ctrl+C to cancel, or wait 5 seconds to continue...
============================================
"@ -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Function to set execution policy (compatible with all versions)
function Set-ExecutionPolicyIfNeeded {
    param (
        [string]$Scope,
        [string]$Policy = "RemoteSigned"
    )
    
    try {
        # Get current policy (compatible way)
        $currentPolicy = Get-ExecutionPolicy -Scope $Scope -ErrorAction SilentlyContinue
        if ($currentPolicy -ne $Policy) {
            Write-Host "Setting execution policy to $Policy for $Scope scope..." -ForegroundColor Yellow
            Set-ExecutionPolicy -ExecutionPolicy $Policy -Scope $Scope -Force -ErrorAction Stop
            Write-Host "Execution policy set successfully for $Scope" -ForegroundColor Green
        } else {
            Write-Host "Execution policy already set to $Policy for $Scope" -ForegroundColor Gray
        }
        return $true
    } catch {
        Write-Host "Failed to set execution policy for $Scope`: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check and start network services
function Test-AndStartNetworkServices {
    $services = @("WlanSvc", "NlaSvc", "NetSetupSvc")
    $allReady = $true
    $serviceStatus = @{}
    
    foreach ($serviceName in $services) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction Stop
            $serviceStatus[$serviceName] = $service.Status
            
            if ($service.Status -ne "Running") {
                Write-Host "Service $serviceName is not ready (Status: $($service.Status)), starting it..." -ForegroundColor Yellow
                Start-Service -Name $serviceName -ErrorAction Stop
                Write-Host "Service $serviceName started successfully" -ForegroundColor Green
                $allReady = $false
            } else {
                Write-Host "Service $serviceName is already running" -ForegroundColor Gray
            }
        } catch {
            Write-Host "Service $serviceName not found or not accessible: $_" -ForegroundColor Yellow
            $serviceStatus[$serviceName] = "Error"
            $allReady = $false
        }
    }
    
    # Show service status summary
    Write-Host "`nNetwork Services Status:" -ForegroundColor Cyan
    foreach ($service in $serviceStatus.GetEnumerator()) {
        $color = switch ($service.Value) {
            "Running" { "Green" }
            "Stopped" { "Yellow" }
            default { "Red" }
        }
        Write-Host "  $($service.Key): $($service.Value)" -ForegroundColor $color
    }
    
    if ($allReady) {
        Write-Host "All network services are ready" -ForegroundColor Green
    } else {
        Write-Host "Some network services required attention" -ForegroundColor Yellow
    }
    
    return $allReady
}

# Function to create scheduled task (compatible with all versions)
function Create-HotspotTask {
    $taskName = "WiFiHotspotSystemStartup"
    
    # Check if task exists (compatible way)
    try {
        $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
        if ($taskExists) {
            Write-Host "Task '$taskName' already exists. Deleting it first..." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
            Write-Host "Existing task deleted successfully" -ForegroundColor Green
        }
    } catch {
        # Task doesn't exist, which is fine
        Write-Host "No existing task found, creating new one..." -ForegroundColor Gray
    }
    
    # Get temp path for script (compatible way)
    $psScriptPath = Join-Path $env:TEMP "hotspot_enable_system.ps1"
    
    # Create the PowerShell script for enabling hotspot at system startup
    $hotspotScript = @'
# WiFi Hotspot Enable Script for System Startup
# Auto-generated by WiFi Hotspot Auto-Setup Script
# Compatible with PowerShell 5.0+

# Set encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Add logging
$logFile = Join-Path $env:TEMP "hotspot_startup.log"
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    try {
        Add-Content -Path $logFile -Value $logMessage -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # If logging fails, continue without it
    }
    Write-Host $logMessage
}

Write-Log "WiFi Hotspot System Startup Script started"
Write-Log "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Log "Running as: $env:USERNAME"

# Function to wait for and start network services
function Wait-AndStartNetworkServices {
    $maxWaitTime = 180  # Maximum wait time in seconds
    $checkInterval = 10   # Check interval in seconds
    $elapsedTime = 0
    
    Write-Log "Waiting for and starting network services..."
    
    $services = @("WlanSvc", "NlaSvc", "NetSetupSvc")
    
    while ($elapsedTime -lt $maxWaitTime) {
        $servicesReady = $true
        
        foreach ($serviceName in $services) {
            try {
                $service = Get-Service -Name $serviceName -ErrorAction Stop
                if ($service.Status -ne "Running") {
                    Write-Log "Service $serviceName not ready (Status: $($service.Status)), starting it..."
                    Start-Service -Name $serviceName -ErrorAction Stop
                    Write-Log "Service $serviceName started successfully"
                    $servicesReady = $false
                } else {
                    Write-Log "Service $serviceName is running"
                }
            } catch {
                Write-Log "Service $serviceName not found or not accessible: $_"
                $servicesReady = $false
            }
        }
        
        if ($servicesReady) {
            Write-Log "All network services are ready!"
            return $true
        }
        
        Write-Log "Waiting for services to stabilize... ($elapsedTime/$maxWaitTime seconds)"
        Start-Sleep -Seconds $checkInterval
        $elapsedTime += $checkInterval
    }
    
    Write-Log "Timeout waiting for network services" "ERROR"
    return $false
}

# Function to enable hotspot (compatible with all versions)
function Enable-Hotspot {
    try {
        Write-Log "Loading Windows Runtime assemblies..."
        
        # Load Windows Runtime assemblies (compatible way)
        Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction Stop
        
        # Load Windows Runtime types
        [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime] | Out-Null
        [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime] | Out-Null
        [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows.Networking.NetworkOperators, ContentType = WindowsRuntime] | Out-Null
        
        Write-Log "Windows Runtime assemblies loaded successfully"
        
        # Get the AsTask generic method
        $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
            $_.Name -eq 'AsTask' -and 
            $_.GetParameters().Count -eq 1 -and 
            $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' 
        })[0]
        
        # Await function for async operations
        Function Await($WinRtTask, $ResultType) {
            $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
            $netTask = $asTask.Invoke($null, @($WinRtTask))
            $netTask.Wait(-1) | Out-Null
            $netTask.Result
        }

        Write-Log "Getting connection profile..."
        # Get connection profile and tethering manager
        $connectionProfile = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile()
        if (-not $connectionProfile) {
            Write-Log "No internet connection profile found, trying to get any network profile..." "WARN"
            # Try to get any network profile
            $profiles = [Windows.Networking.Connectivity.NetworkInformation]::GetConnectionProfiles()
            if ($profiles.Count -gt 0) {
                $connectionProfile = $profiles[0]
                Write-Log "Using first available network profile: $($connectionProfile.ProfileName)"
            } else {
                Write-Log "No network profiles found" "ERROR"
                return $false
            }
        }
        
        $tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager]::CreateFromConnectionProfile($connectionProfile)
        
        # Check current status
        $status = $tetheringManager.TetheringOperationalState
        Write-Log "Current hotspot status: $status"
        
        if ($status -eq "On") {
            Write-Log "Hotspot is already enabled"
            return $true
        }
        
        Write-Log "Starting Mobile Hotspot..."
        # Start Mobile Hotspot
        $result = Await ($tetheringManager.StartTetheringAsync()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
        
        if ($result.Status -eq "Success") {
            Write-Log "WiFi hotspot enabled successfully at system startup!" "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to enable WiFi hotspot: $($result.Status)" "ERROR"
            if ($result.AdditionalErrorMessage) {
                Write-Log "Additional error: $($result.AdditionalErrorMessage)" "ERROR"
            }
            return $false
        }
    } catch {
        Write-Log "Error enabling hotspot: $_" "ERROR"
        return $false
    }
}

# Main execution
try {
    Write-Log "Starting hotspot enablement process..."
    
    # Wait for and start network services
    if (Wait-AndStartNetworkServices) {
        # Wait a bit more for services to fully initialize
        Write-Log "Waiting for services to fully initialize..."
        Start-Sleep -Seconds 15
        
        # Enable hotspot
        if (Enable-Hotspot) {
            Write-Log "Hotspot enablement process completed successfully" "SUCCESS"
        } else {
            Write-Log "Hotspot enablement failed" "ERROR"
        }
    } else {
        Write-Log "Network services not ready, skipping hotspot enablement" "ERROR"
    }
} catch {
    Write-Log "Unexpected error: $_" "ERROR"
}

Write-Log "WiFi Hotspot System Startup Script finished"
'@
    
    # Save the hotspot script
    try {
        $hotspotScript | Out-File -FilePath $psScriptPath -Encoding UTF8 -Force -ErrorAction Stop
        Write-Host "Created system startup hotspot script at: $psScriptPath" -ForegroundColor Green
    } catch {
        Write-Host "Failed to create hotspot script: $_" -ForegroundColor Red
        return $false
    }
    
    # Create the scheduled task action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File `"$psScriptPath`""
    
    # Create the trigger (system startup trigger with delay)
    try {
        $trigger = New-ScheduledTaskTrigger -AtStartup
        # Set delay property (compatible way)
        if ($trigger.Delay) {
            $trigger.Delay = "PT20S"  # 20 seconds delay after system startup
            Write-Host "Created system startup trigger with 20 seconds delay" -ForegroundColor Gray
        } else {
            Write-Host "Created system startup trigger without delay" -ForegroundColor Yellow
        }
    } catch {
        try {
            $trigger = New-ScheduledTaskTrigger -AtStartup
            Write-Host "Created system startup trigger (basic)" -ForegroundColor Yellow
        } catch {
            Write-Host "Failed to create startup trigger: $_" -ForegroundColor Red
            return $false
        }
    }
    
    # Create the principal (run as SYSTEM with highest privileges)
    try {
        $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        Write-Host "Created SYSTEM principal with highest privileges" -ForegroundColor Gray
    } catch {
        try {
            $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
            Write-Host "Created user principal as fallback" -ForegroundColor Yellow
        } catch {
            Write-Host "Failed to create principal: $_" -ForegroundColor Red
            return $false
        }
    }
    
    # Create the settings
    try {
        $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries -DontStopOnIdleEnd -WakeToRun
        Write-Host "Created task settings" -ForegroundColor Gray
    } catch {
        Write-Host "Failed to create settings: $_" -ForegroundColor Red
        return $false
    }
    
    # Register the scheduled task
    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Automatically enables WiFi hotspot at system startup" -Force -ErrorAction Stop
        Write-Host "Scheduled task '$taskName' created successfully!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed to create scheduled task: $_" -ForegroundColor Red
        return $false
    }
}

# Function to enable hotspot immediately (compatible with all versions)
function Enable-HotspotNow {
    try {
        # Load Windows Runtime assemblies
        Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction Stop
        
        # Load Windows Runtime types
        [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime] | Out-Null
        [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime] | Out-Null
        [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows.Networking.NetworkOperators, ContentType = WindowsRuntime] | Out-Null
        
        # Get the AsTask generic method
        $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
            $_.Name -eq 'AsTask' -and 
            $_.GetParameters().Count -eq 1 -and 
            $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' 
        })[0]
        
        # Await function for async operations
        Function Await($WinRtTask, $ResultType) {
            $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
            $netTask = $asTask.Invoke($null, @($WinRtTask))
            $netTask.Wait(-1) | Out-Null
            $netTask.Result
        }

        # Get connection profile and tethering manager
        $connectionProfile = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile()
        $tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager]::CreateFromConnectionProfile($connectionProfile)
        
        # Check current status
        $status = $tetheringManager.TetheringOperationalState
        Write-Host "Current hotspot status: $status" -ForegroundColor Cyan
        
        # Start Mobile Hotspot
        $result = Await ($tetheringManager.StartTetheringAsync()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
        
        if ($result.Status -eq "Success") {
            Write-Host "WiFi hotspot enabled successfully!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Failed to enable WiFi hotspot: $($result.Status)" -ForegroundColor Red
            if ($result.AdditionalErrorMessage) {
                Write-Host "Additional error: $($result.AdditionalErrorMessage)" -ForegroundColor Red
            }
            return $false
        }
    } catch {
        Write-Host "Error enabling hotspot: $_" -ForegroundColor Red
        return $false
    }
}

# Main execution
try {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Starting WiFi Hotspot Setup Process" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Step 1: Set execution policies
    Write-Host "`nStep 1: Setting execution policies..." -ForegroundColor Cyan
    $policySet = Set-ExecutionPolicyIfNeeded -Scope "CurrentUser"
    $policySet = $policySet -and (Set-ExecutionPolicyIfNeeded -Scope "LocalMachine")
    
    if ($policySet) {
        Write-Host "Execution policies configured successfully" -ForegroundColor Green
    } else {
        Write-Host "Warning: Some execution policies could not be set" -ForegroundColor Yellow
    }
    
    # Step 2: Check and start network services
    Write-Host "`nStep 2: Checking and starting network services..." -ForegroundColor Cyan
    $servicesReady = Test-AndStartNetworkServices
    if (-not $servicesReady) {
        Write-Host "Warning: Some network services may not be running properly." -ForegroundColor Yellow
    }
    
    # Step 3: Create scheduled task for system startup
    Write-Host "`nStep 3: Creating scheduled task for system startup..." -ForegroundColor Cyan
    $taskCreated = Create-HotspotTask
    
    if ($taskCreated) {
        Write-Host "System startup scheduled task setup completed successfully!" -ForegroundColor Green
        Write-Host "The hotspot will automatically start 20 seconds after Windows boots." -ForegroundColor Green
        Write-Host "Log file will be created at: $env:TEMP\hotspot_startup.log" -ForegroundColor Gray
    } else {
        Write-Host "Failed to set up system startup scheduled task" -ForegroundColor Red
    }
    
    # Step 4: Enable hotspot immediately
    Write-Host "`nStep 4: Enabling WiFi hotspot now..." -ForegroundColor Cyan
    $hotspotEnabled = Enable-HotspotNow
    
    # Final summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Setup Process Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    Write-Host "Execution Policies: $(if ($policySet) { "[OK] Configured" } else { "[WARN] Issues" })" -ForegroundColor $(if ($policySet) { "Green" } else { "Yellow" })
    Write-Host "Network Services: $(if ($servicesReady) { "[OK] Ready" } else { "[WARN] Issues" })" -ForegroundColor $(if ($servicesReady) { "Green" } else { "Yellow" })
    Write-Host "Scheduled Task: $(if ($taskCreated) { "[OK] Created" } else { "[FAIL] Failed" })" -ForegroundColor $(if ($taskCreated) { "Green" } else { "Red" })
    Write-Host "Hotspot Status: $(if ($hotspotEnabled) { "[OK] Active" } else { "[FAIL] Failed" })" -ForegroundColor $(if ($hotspotEnabled) { "Green" } else { "Red" })
    
    if ($hotspotEnabled -and $taskCreated) {
        Write-Host "`nAll operations completed successfully!" -ForegroundColor Green
        Write-Host "WiFi hotspot is now active and will auto-start on boot!" -ForegroundColor Green
    } else {
        Write-Host "`nSome operations failed. Please check the error messages above." -ForegroundColor Yellow
        Write-Host "Log file: $env:TEMP\hotspot_startup.log" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "`nAn unexpected error occurred: $_" -ForegroundColor Red
    Write-Host "Log file: $env:TEMP\hotspot_startup.log" -ForegroundColor Gray
}

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
try {
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} catch {
    # Fallback if ReadKey fails
    Read-Host "Press Enter to exit"
}
