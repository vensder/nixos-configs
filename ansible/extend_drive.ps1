# PowerShell script to extend C: drive and initialize Disk 1 with GPT
# Must be run as Administrator

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Disk Management Script ===" -ForegroundColor Cyan
Write-Host ""

# ===== PART 1: Extend C: Drive on Disk 0 =====
Write-Host "PART 1: Extending C: Drive on Disk 0" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Display current Disk 0 configuration
Write-Host "Current Disk 0 configuration:" -ForegroundColor Yellow
Get-Partition -DiskNumber 0 | Select-Object PartitionNumber, DriveLetter, Size, @{Name="SizeGB";Expression={[math]::Round($_.Size/1GB,2)}} | Format-Table

# Get the C: drive partition
$partition = Get-Partition -DriveLetter C -ErrorAction SilentlyContinue

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

# Confirm before proceeding with C: drive extension
$confirmation = Read-Host "Do you want to extend C: drive to maximum size? (Y/N)"

if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
    try {
        Write-Host "Extending C: partition..." -ForegroundColor Yellow
        Resize-Partition -DriveLetter C -Size $maxSize
        Write-Host "SUCCESS: C: drive has been extended!" -ForegroundColor Green
        Write-Host ""

        # Display updated configuration
        Write-Host "Updated Disk 0 configuration:" -ForegroundColor Yellow
        Get-Partition -DiskNumber 0 | Select-Object PartitionNumber, DriveLetter, Size, @{Name="SizeGB";Expression={[math]::Round($_.Size/1GB,2)}} | Format-Table

    } catch {
        Write-Host "ERROR: Failed to extend C: partition!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "Skipped extending C: drive." -ForegroundColor Yellow
}

Write-Host ""
Write-Host ""

# ===== PART 2: Initialize and Format Disk 1 =====
Write-Host "PART 2: Initialize and Format Disk 1" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if Disk 1 exists
$disk1 = Get-Disk -Number 1 -ErrorAction SilentlyContinue

if ($null -eq $disk1) {
    Write-Host "WARNING: Disk 1 not found. Skipping Disk 1 initialization." -ForegroundColor Yellow
    Write-Host "Script completed." -ForegroundColor Green
    exit 0
}

# Display Disk 1 information
Write-Host "Disk 1 Information:" -ForegroundColor Yellow
$disk1 | Select-Object Number, FriendlyName, PartitionStyle, @{Name="SizeGB";Expression={[math]::Round($_.Size/1GB,2)}}, OperationalStatus | Format-List

# Check if disk is already initialized
if ($disk1.PartitionStyle -ne "RAW") {
    Write-Host "WARNING: Disk 1 is already initialized with partition style: $($disk1.PartitionStyle)" -ForegroundColor Yellow
    Write-Host "Existing partitions:" -ForegroundColor Yellow
    Get-Partition -DiskNumber 1 -ErrorAction SilentlyContinue | Select-Object PartitionNumber, DriveLetter, Size, @{Name="SizeGB";Expression={[math]::Round($_.Size/1GB,2)}} | Format-Table

    $reinitialize = Read-Host "Do you want to REINITIALIZE Disk 1? This will DELETE ALL DATA on Disk 1! (Y/N)"

    if ($reinitialize -ne 'Y' -and $reinitialize -ne 'y') {
        Write-Host "Skipped Disk 1 initialization." -ForegroundColor Yellow
        Write-Host "Script completed." -ForegroundColor Green
        exit 0
    }

    Write-Host "Clearing disk..." -ForegroundColor Yellow
    Clear-Disk -Number 1 -RemoveData -Confirm:$false
}

# Confirm before initializing
Write-Host ""
Write-Host "This will initialize Disk 1 with GPT partition table and create a new volume." -ForegroundColor Yellow
$confirmation2 = Read-Host "Do you want to proceed with initializing Disk 1? (Y/N)"

if ($confirmation2 -ne 'Y' -and $confirmation2 -ne 'y') {
    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    exit 0
}

try {
    # Initialize disk with GPT
    Write-Host "Initializing Disk 1 with GPT..." -ForegroundColor Yellow
    Initialize-Disk -Number 1 -PartitionStyle GPT

    # Create new partition using all available space
    Write-Host "Creating new partition..." -ForegroundColor Yellow
    $newPartition = New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter

    # Format the partition as NTFS
    Write-Host "Formatting partition as NTFS..." -ForegroundColor Yellow
    $driveLetter = $newPartition.DriveLetter
    Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -NewFileSystemLabel "Data" -Confirm:$false

    Write-Host ""
    Write-Host "SUCCESS: Disk 1 has been initialized and formatted!" -ForegroundColor Green
    Write-Host "New drive letter: $driveLetter" -ForegroundColor Green
    Write-Host ""

    # Display final configuration
    Write-Host "Disk 1 final configuration:" -ForegroundColor Yellow
    Get-Partition -DiskNumber 1 | Select-Object PartitionNumber, DriveLetter, Size, @{Name="SizeGB";Expression={[math]::Round($_.Size/1GB,2)}} | Format-Table

} catch {
    Write-Host "ERROR: Failed to initialize/format Disk 1!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All operations completed successfully!" -ForegroundColor Green
