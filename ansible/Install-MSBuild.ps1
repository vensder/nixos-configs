#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs MSBuild 14 and 16 on a machine that already has MSBuild 17.

.DESCRIPTION
    This script installs:
    - MSBuild 14 (Visual Studio 2015 Build Tools)
    - MSBuild 16 (Visual Studio 2019 Build Tools)

    MSBuild versions can coexist on the same machine.
#>

$ErrorActionPreference = "Stop"

# Create temp directory for downloads
$tempDir = Join-Path $env:TEMP "MSBuildInstall"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MSBuild 14 & 16 Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if MSBuild 17 exists (as mentioned in requirements)
$msbuild17Paths = @(
    "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\amd64\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\amd64\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\amd64\MSBuild.exe"
)

$msbuild17Found = $false
foreach ($path in $msbuild17Paths) {
    if (Test-Path $path) {
        Write-Host "[OK] MSBuild 17 detected at: $path" -ForegroundColor Green
        $msbuild17Found = $true
        break
    }
}
if (-not $msbuild17Found) {
    Write-Host "[WARNING] MSBuild 17 not found at expected locations" -ForegroundColor Yellow
}
Write-Host ""

# Function to download file with progress
function Download-File {
    param(
        [string]$Url,
        [string]$Output
    )

    Write-Host "Downloading: $Output" -ForegroundColor Yellow
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $Output -UseBasicParsing
        $ProgressPreference = 'Continue'
        Write-Host "[OK] Download complete" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[ERROR] Download failed: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check if MSBuild version exists
function Test-MSBuildVersion {
    param([string]$Version)

    $paths = @(
        "C:\Program Files (x86)\MSBuild\$Version\Bin\MSBuild.exe",
        "C:\Program Files\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

# ========================================
# Install MSBuild 14 (VS 2015 Build Tools)
# ========================================
Write-Host "Installing MSBuild 14 (Visual Studio 2015 Build Tools)..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan

$msbuild14Existing = Test-MSBuildVersion "14.0"
if ($msbuild14Existing) {
    Write-Host "[WARNING] MSBuild 14 already installed at: $msbuild14Existing" -ForegroundColor Yellow
    Write-Host "    Skipping installation..." -ForegroundColor Yellow
} else {
    $vs2015BuildToolsUrl = "https://download.microsoft.com/download/E/E/D/EEDF18A8-4AED-4CE0-BEBE-70A83094FC5A/BuildTools_Full.exe"
    $vs2015Installer = Join-Path $tempDir "BuildTools_VS2015.exe"

    if (Download-File -Url $vs2015BuildToolsUrl -Output $vs2015Installer) {
        Write-Host "Installing Visual Studio 2015 Build Tools..." -ForegroundColor Yellow
        Write-Host "(This may take several minutes, please wait...)" -ForegroundColor Yellow

        $installArgs = @(
            "/Quiet",
            "/NoRestart",
            "/Full"
        )

        $process = Start-Process -FilePath $vs2015Installer -ArgumentList $installArgs -Wait -PassThru

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Host "[OK] MSBuild 14 installed successfully" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        }
    }
}
Write-Host ""

# ========================================
# Install MSBuild 16 (VS 2019 Build Tools)
# ========================================
Write-Host "Installing MSBuild 16 (Visual Studio 2019 Build Tools)..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan

$msbuild16Existing = Test-MSBuildVersion "Current"
if ($msbuild16Existing -and $msbuild16Existing -like "*2019*") {
    Write-Host "[WARNING] MSBuild 16 already installed at: $msbuild16Existing" -ForegroundColor Yellow
    Write-Host "    Skipping installation..." -ForegroundColor Yellow
} else {
    # Download VS Build Tools bootstrapper
    $vs2019BootstrapperUrl = "https://aka.ms/vs/16/release/vs_buildtools.exe"
    $vs2019Installer = Join-Path $tempDir "vs_buildtools2019.exe"

    if (Download-File -Url $vs2019BootstrapperUrl -Output $vs2019Installer) {
        Write-Host "Installing Visual Studio 2019 Build Tools..." -ForegroundColor Yellow
        Write-Host "(This may take several minutes, please wait...)" -ForegroundColor Yellow

        $installArgs = @(
            "--quiet",
            "--wait",
            "--norestart",
            "--nocache",
            "--add", "Microsoft.VisualStudio.Workload.MSBuildTools",
            "--add", "Microsoft.VisualStudio.Workload.VCTools"
        )

        $process = Start-Process -FilePath $vs2019Installer -ArgumentList $installArgs -Wait -PassThru

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Host "[OK] MSBuild 16 installed successfully" -ForegroundColor Green
            if ($process.ExitCode -eq 3010) {
                Write-Host "[WARNING] A restart is required to complete the installation" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[ERROR] Installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        }
    }
}
Write-Host ""

# ========================================
# Verify Installations
# ========================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verifying MSBuild Installations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$msbuildVersions = @(
    @{Version="14.0"; Paths=@("C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe",
                               "C:\Program Files (x86)\MSBuild\14.0\Bin\amd64\MSBuild.exe")},
    @{Version="16.0"; Paths=@("C:\Program Files\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
                               "C:\Program Files\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\amd64\MSBuild.exe",
                               "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
                               "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\amd64\MSBuild.exe")},
    @{Version="17.0"; Paths=@("C:\Program Files\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
                               "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64\MSBuild.exe",
                               "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
                               "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64\MSBuild.exe",
                               "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
                               "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\amd64\MSBuild.exe",
                               "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
                               "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\amd64\MSBuild.exe",
                               "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
                               "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\amd64\MSBuild.exe")}
)

foreach ($version in $msbuildVersions) {
    $found = $false
    foreach ($path in $version.Paths) {
        if (Test-Path $path) {
            Write-Host "[OK] MSBuild $($version.Version) found:" -ForegroundColor Green
            Write-Host "    $path" -ForegroundColor Gray

            # Get version info
            $versionInfo = & $path /version /nologo 2>&1 | Select-Object -First 1
            Write-Host "    Version: $versionInfo" -ForegroundColor Gray
            $found = $true
            break
        }
    }
    if (-not $found) {
        Write-Host "[ERROR] MSBuild $($version.Version) not found" -ForegroundColor Red
    }
    Write-Host ""
}

# Cleanup
Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "[OK] Cleanup complete" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now use different MSBuild versions by specifying their full paths." -ForegroundColor White
Write-Host "Or use the Developer Command Prompt for each Visual Studio version." -ForegroundColor White
