<#
.SYNOPSIS
    Collects basic computer inventory information.

.DESCRIPTION
    This script gathers common system details such as:
    - Computer name
    - Operating system
    - IP address
    - Disk space information

    Useful for IT inventory and troubleshooting.

.NOTES
    Author: Zaini
    Run as: Standard user (some details may require admin)
#>

Write-Host "Collecting computer inventory..." -ForegroundColor Cyan

# Computer name
$ComputerName = $env:COMPUTERNAME

# Operating system info
$OS = Get-CimInstance Win32_OperatingSystem

# IP address (first active IPv4)
$IPAddress = Get-NetIPAddress -AddressFamily IPv4 `
    | Where-Object { $_.IPAddress -notlike "169.*" -and $_.InterfaceOperationalStatus -eq "Up" } `
    | Select-Object -First 1 -ExpandProperty IPAddress

# Disk information
$Disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
                  @{Name="SizeGB"; Expression={ [math]::Round($_.Size / 1GB, 2) }},
                  @{Name="FreeGB"; Expression={ [math]::Round($_.FreeSpace / 1GB, 2) }}

# Output results
Write-Host "Computer Name : $ComputerName"
Write-Host "OS            : $($OS.Caption)"
Write-Host "IP Address    : $IPAddress"
Write-Host ""
Write-Host "Disk Information:"
$Disks | Format-Table -AutoSize
