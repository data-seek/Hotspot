# WiFi Hotspot Auto-Setup Launcher
# This launcher handles elevation for remote execution
# Version: 1.0.0

# Script information
$LauncherInfo = @{
    Name = "WiFi Hotspot Auto-Setup Launcher"
    Version = "1.0.0"
    MainScriptURL = "https://get.data-seek.cn/hotspot-main.ps1"
    Description = "Launcher for WiFi Hotspot Auto-Setup with automatic elevation"
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Show information
Write-Host @"
WiFi Hotspot Auto-Setup Launcher v$($LauncherInfo.Version)
============================================
Main Script: $($LauncherInfo.MainScriptURL)
PowerShell Version: $($PSVersionTable.PSVersion)
Administrator: $(if (Test-Administrator) { "YES" } else { "NO" })
Mode: LIVE MODE
"@ -ForegroundColor Green

# If not admin, restart with admin rights
if (-not (Test-Administrator)) {
    Write-Host "Administrator privileges required. Requesting elevation..." -ForegroundColor Yellow
    
    try {
        # Create elevation command
        $elevateCommand = "irm $($LauncherInfo.MainScriptURL) | iex"
        
        Write-Host "Starting elevated PowerShell process..." -ForegroundColor Cyan
        
        # Start new PowerShell process with admin rights
        Start-Process PowerShell -Verb RunAs -ArgumentList "-Command `"$elevateCommand`""
        exit 0
    } catch {
        Write-Host "Failed to elevate privileges: $_" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator manually:" -ForegroundColor Yellow
        Write-Host "1. Right-click PowerShell" -ForegroundColor White
        Write-Host "2. Select 'Run as Administrator'" -ForegroundColor White
        Write-Host "3. Run: irm $($LauncherInfo.MainScriptURL) | iex" -ForegroundColor White
        exit 1
    }
}

# We're running as admin, download and execute main script
try {
    Write-Host "Downloading main setup script..." -ForegroundColor Cyan
    
    # Download with timeout and retry
    $maxRetries = 3
    $retryCount = 0
    $scriptContent = $null
    
    while ($retryCount -lt $maxRetries -and -not $scriptContent) {
        try {
            $scriptContent = Invoke-WebRequest -Uri $LauncherInfo.MainScriptURL -UseBasicParsing -TimeoutSec 30
            if ($scriptContent.StatusCode -ne 200) {
                throw "HTTP $($scriptContent.StatusCode)"
            }
        } catch {
            $retryCount++
            Write-Host "Download attempt $retryCount failed: $_" -ForegroundColor Yellow
            if ($retryCount -lt $maxRetries) {
                Write-Host "Retrying in 2 seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
    }
    
    if (-not $scriptContent) {
        throw "Failed to download main script after $maxRetries attempts"
    }
    
    Write-Host "Executing main setup script..." -ForegroundColor Cyan
    Invoke-Expression $scriptContent.Content
    
} catch {
    Write-Host "Failed to download or execute main script: $_" -ForegroundColor Red
    Write-Host "Please check your internet connection and try again." -ForegroundColor Yellow
    Write-Host "Manual download: $($LauncherInfo.MainScriptURL)" -ForegroundColor Gray
    exit 1
}
