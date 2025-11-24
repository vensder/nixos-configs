# Windows 11 VM Setup Script
# Run this in PowerShell as Administrator

Write-Host "Starting Windows 11 VM setup..." -ForegroundColor Green

# 1. Install Chocolatey (package manager)
Write-Host "[1/6] Installing Chocolatey..." -ForegroundColor Yellow
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 2. Install packages
Write-Host "[2/6] Installing packages..." -ForegroundColor Yellow

# GitLab Runner
Write-Host "Installing GitLab Runner..."
choco install gitlab-runner -y

# MSBuild 17 (Visual Studio Build Tools 2022)
Write-Host "Installing MSBuild 17 (VS Build Tools 2022)..."
Write-Host "This may take 10-15 minutes..."
choco install visualstudio2022buildtools --package-parameters "--quiet --wait --add Microsoft.VisualStudio.Workload.MSBuildTools --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended" -y

# Python 3
Write-Host "Installing Python 3..."
choco install python -y

# Inno Setup
Write-Host "Installing Inno Setup..."
choco install innosetup -y

# Git
Write-Host "Installing Git..."
choco install git -y

# 3. Set ExecutionPolicy to RemoteSigned
Write-Host "[3/6] Setting ExecutionPolicy to RemoteSigned..." -ForegroundColor Yellow
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

# 4. Enable long paths
Write-Host "[4/6] Enabling long paths..." -ForegroundColor Yellow
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1
reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f

# 5. Refresh environment variables
Write-Host "[5/6] Refreshing environment variables..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Add MSBuild to system PATH permanently
Write-Host "Adding MSBuild to system PATH..." -ForegroundColor Cyan
$msbuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64"
if (Test-Path $msbuildPath) {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$msbuildPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$msbuildPath", "Machine")
        Write-Host "MSBuild path added to system PATH" -ForegroundColor Green
    } else {
        Write-Host "MSBuild path already in system PATH" -ForegroundColor Yellow
    }
    # Refresh current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "Warning: MSBuild path not found at expected location" -ForegroundColor Red
}

# 6. Verify installations
Write-Host "[6/6] Verifying installations..." -ForegroundColor Yellow
Write-Host "GitLab Runner: " -NoNewline
try { gitlab-runner --version; Write-Host "OK" -ForegroundColor Green } catch { Write-Host "Failed" -ForegroundColor Red }

Write-Host "MSBuild: " -NoNewline
$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
if ($msbuild) {
    Write-Host "OK - $($msbuild.Source)" -ForegroundColor Green
} else {
    # Check if it exists but not in PATH yet
    $msbuildExe = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64\MSBuild.exe"
    if (Test-Path $msbuildExe) {
        Write-Host "Installed but needs PowerShell restart to be in PATH" -ForegroundColor Yellow
    } else {
        Write-Host "Failed - Not found" -ForegroundColor Red
    }
}

Write-Host "Python: " -NoNewline
try { python --version; Write-Host "OK" -ForegroundColor Green } catch { Write-Host "Failed" -ForegroundColor Red }

Write-Host "Git: " -NoNewline
try { git --version; Write-Host "OK" -ForegroundColor Green } catch { Write-Host "Failed" -ForegroundColor Red }

Write-Host "Inno Setup: " -NoNewline
if (Test-Path "C:\Program Files (x86)\Inno Setup 6\ISCC.exe") { Write-Host "OK" -ForegroundColor Green } else { Write-Host "Failed" -ForegroundColor Red }

Write-Host "Long Paths: " -NoNewline
$longPaths = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled'
if ($longPaths.LongPathsEnabled -eq 1) { Write-Host "Enabled" -ForegroundColor Green } else { Write-Host "Disabled" -ForegroundColor Red }

Write-Host "Execution Policy: " -NoNewline
$execPolicy = Get-ExecutionPolicy
Write-Host "$execPolicy" -ForegroundColor Green

Write-Host "========================================"  -ForegroundColor Cyan
Write-Host "Setup complete! Please restart the VM." -ForegroundColor Cyan
Write-Host "========================================"  -ForegroundColor Cyan
