# Rename Local Admin User and Set New Password
# This script must be run as Administrator

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Variables
$oldUsername = "local_bambino"
$newUsername = "local_goblino"

Write-Host "=== Local User Rename and Password Reset ===" -ForegroundColor Cyan
Write-Host ""

# Check if the old username exists
try {
    $user = Get-LocalUser -Name $oldUsername -ErrorAction Stop
    Write-Host "Found user: $oldUsername" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: User '$oldUsername' not found on this system" -ForegroundColor Red
    exit 1
}

# Check if the new username already exists
try {
    $existingUser = Get-LocalUser -Name $newUsername -ErrorAction SilentlyContinue
    if ($existingUser) {
        Write-Host "ERROR: User '$newUsername' already exists" -ForegroundColor Red
        exit 1
    }
}
catch {
    # This is expected if user doesn't exist
}

# Prompt for new password
Write-Host "Please enter the new password for user '$newUsername':" -ForegroundColor Yellow
$securePassword = Read-Host -AsSecureString

Write-Host "Please confirm the password:" -ForegroundColor Yellow
$confirmPassword = Read-Host -AsSecureString

# Convert SecureStrings to plain text for comparison
$ptr1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$ptr2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmPassword)
$password1 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr1)
$password2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr2)

if ($password1 -ne $password2) {
    Write-Host "ERROR: Passwords do not match" -ForegroundColor Red
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr1)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr2)
    exit 1
}

# Clean up plain text passwords from memory
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr1)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr2)

Write-Host ""
Write-Host "Renaming user from '$oldUsername' to '$newUsername'..." -ForegroundColor Yellow

# Rename the user
try {
    Rename-LocalUser -Name $oldUsername -NewName $newUsername -ErrorAction Stop
    Write-Host "Successfully renamed user to '$newUsername'" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to rename user - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Set the new password
try {
    Set-LocalUser -Name $newUsername -Password $securePassword -ErrorAction Stop
    Write-Host "Successfully set new password for '$newUsername'" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to set password - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Operation Completed Successfully ===" -ForegroundColor Green
Write-Host "User '$oldUsername' has been renamed to '$newUsername' with a new password" -ForegroundColor Green
