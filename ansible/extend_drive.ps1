# PowerShell script to extend C: drive to maximum available space
# Must be run as Administrator

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Extending C: Drive Volume ===" -ForegroundColor Cyan
Write-Host ""

# Display current disk configuration
Write-Host "Current disk configuration:" -ForegroundColor Yellow
Get-Partition -DiskNumber 0 | Select-Object PartitionNumber, DriveLetter, Size, @{Name="SizeGB";Expression={[math]::Round($_.Size/1GB,2)}} | Format-Table

# Get the C: drive partition
$partition = Get-Partition -DriveLetter C

if ($null -eq $partition) {
    Write-Host "ERROR: C: drive not found!" -ForegroundColor Red
    exit 1
}

# Get the maximum size the partition can be extended to
$maxSize = (Get-PartitionSupportedSize -DriveLetter C).SizeMax

Write-Host "Current C: drive size: $([math]::Round($partition.Size/1GB,2)) GB" -ForegroundColor Green
Write-Host "Maximum possible size: $([math]::Round($maxSize/1GB,2)) GB" -ForegroundColor Green
Write-Host "Space to be added: $([math]::Round(($maxSize - $partition.Size)/1GB,2)) GB" -ForegroundColor Green
Write-Host ""

# Confirm before proceeding
$confirmation = Read-Host "Do you want to extend C: drive to maximum size? (Y/N)"

if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    exit 0
}

# Extend the partition
try {
    Write-Host "Extending partition..." -ForegroundColor Yellow
    Resize-Partition -DriveLetter C -Size $maxSize
    Write-Host "SUCCESS: C: drive has been extended!" -ForegroundColor Green
    Write-Host ""
    
    # Display updated configuration
    Write-Host "Updated disk configuration:" -ForegroundColor Yellow
    Get-Partition -DiskNumber 0 | Select-Object PartitionNumber, DriveLetter, Size, @{Name="SizeGB";Expression={[math]::Round($_.Size/1GB,2)}} | Format-Table
    
} catch {
    Write-Host "ERROR: Failed to extend partition!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "Operation completed successfully!" -ForegroundColor Green
