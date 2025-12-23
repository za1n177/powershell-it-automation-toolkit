<#
.SYNOPSIS
    Creates a new Active Directory user for onboarding.

.DESCRIPTION
    - Creates a user in a target OU
    - Sets basic attributes (display name, UPN, department, title)
    - Enables the account
    - Adds user to one or more AD groups (optional)
    - Forces password change at first logon (optional)

.REQUIREMENTS
    - ActiveDirectory module (RSAT)
    - Domain connectivity and permissions to create users

.EXAMPLE
    .\New-ADUser-Onboarding.ps1 `
      -SamAccountName "jdoe" `
      -GivenName "John" `
      -Surname "Doe" `
      -DisplayName "John Doe" `
      -UserPrincipalName "jdoe@contoso.com" `
      -OU "OU=Users,DC=contoso,DC=com" `
      -TempPassword "P@ssw0rd!123" `
      -Groups "GG-M365-Users","GG-VPN-Users" `
      -ForceChangePasswordAtLogon

.NOTES
    Author: Zaini
    Safe for lab/testing. Review before production use.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SamAccountName,

    [Parameter(Mandatory=$true)]
    [string]$GivenName,

    [Parameter(Mandatory=$true)]
    [string]$Surname,

    [Parameter(Mandatory=$true)]
    [string]$DisplayName,

    [Parameter(Mandatory=$true)]
    [string]$UserPrincipalName,

    [Parameter(Mandatory=$true)]
    [string]$OU,

    [Parameter(Mandatory=$true)]
    [string]$TempPassword,

    [Parameter(Mandatory=$false)]
    [string]$Department,

    [Parameter(Mandatory=$false)]
    [string]$Title,

    [Parameter(Mandatory=$false)]
    [string[]]$Groups,

    [Parameter(Mandatory=$false)]
    [switch]$ForceChangePasswordAtLogon
)

# --- Pre-checks ---
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "❌ ActiveDirectory module not found. Install RSAT or run on a domain admin workstation." -ForegroundColor Red
    exit 1
}

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "Creating AD user: $DisplayName ($SamAccountName)" -ForegroundColor Cyan
Write-Host "OU: $OU" -ForegroundColor DarkGray
Write-Host "----------------------------------------"

# Prevent duplicates
$existing = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "❌ User already exists: $SamAccountName" -ForegroundColor Red
    exit 1
}

try {
    $securePass = ConvertTo-SecureString $TempPassword -AsPlainText -Force

    # Create user
    New-ADUser `
        -Name $DisplayName `
        -SamAccountName $SamAccountName `
        -GivenName $GivenName `
        -Surname $Surname `
        -DisplayName $DisplayName `
        -UserPrincipalName $UserPrincipalName `
        -Path $OU `
        -AccountPassword $securePass `
        -Enabled $true `
        -ChangePasswordAtLogon:$ForceChangePasswordAtLogon.IsPresent `
        -Department $Department `
        -Title $Title `
        -PassThru | Out-Null

    Write-Host "✅ User created successfully." -ForegroundColor Green

} catch {
    Write-Host "❌ Failed to create user: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Add to groups (optional)
if ($Groups -and $Groups.Count -gt 0) {
    Write-Host "`nAdding user to groups..." -ForegroundColor Yellow
    foreach ($g in $Groups) {
        try {
            Add-ADGroupMember -Identity $g -Members $SamAccountName -ErrorAction Stop
            Write-Host "   ✅ Added to: $g" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ Failed to add to $g : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "`nGroups: (Skipped - none provided)" -ForegroundColor DarkGray
}

Write-Host "`nDone." -ForegroundColor Cyan
