<#
.SYNOPSIS
    Creates a new Active Directory user for onboarding.

.DESCRIPTION
    - Creates a user in a target OU
    - Sets key attributes (display name, UPN, department, title)
    - Enables the account
    - Optionally adds the user to AD groups
    - Supports -WhatIf for safe dry-run testing

.REQUIREMENTS
    - ActiveDirectory module (RSAT)
    - Domain connectivity + permissions to create users

.EXAMPLE
    # Dry-run (no changes made)
    .\New-ADUser-Onboarding.ps1 `
      -SamAccountName "jdoe" `
      -GivenName "John" `
      -Surname "Doe" `
      -DisplayName "John Doe" `
      -UserPrincipalName "jdoe@contoso.com" `
      -OU "OU=Users,DC=contoso,DC=com" `
      -TempPassword "P@ssw0rd!123" `
      -Groups "GG-M365-Users","GG-VPN-Users" `
      -ForceChangePasswordAtLogon `
      -WhatIf

.EXAMPLE
    # Real run
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
    For lab/testing. Review before production use.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$SamAccountName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$GivenName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Surname,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$DisplayName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$UserPrincipalName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$OU,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
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
    Write-Host "❌ ActiveDirectory module not found." -ForegroundColor Red
    Write-Host "Install RSAT or run on a domain-joined admin workstation/server with AD tools." -ForegroundColor Yellow
    exit 1
}

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "Creating AD user: $DisplayName ($SamAccountName)" -ForegroundColor Cyan
Write-Host "Target OU: $OU" -ForegroundColor DarkGray
Write-Host "----------------------------------------"

# Prevent duplicates
$existing = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "❌ User already exists: $SamAccountName" -ForegroundColor Red
    exit 1
}

# Convert password
$securePass = ConvertTo-SecureString $TempPassword -AsPlainText -Force

try {
    if ($PSCmdlet.ShouldProcess("AD User '$SamAccountName' in '$OU'", "Create")) {

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
            -ErrorAction Stop | Out-Null

        Write-Host "✅ User created successfully." -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Failed to create user: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Add to groups (optional)
if ($Groups -and $Groups.Count -gt 0) {
    Write-Host "`nAdding user to groups..." -ForegroundColor Yellow
    foreach ($g in $Groups) {
        try {
            if ($PSCmdlet.ShouldProcess("Group '$g'", "Add member '$SamAccountName'")) {
                Add-ADGroupMember -Identity $g -Members $SamAccountName -ErrorAction Stop
                Write-Host "   ✅ Added to: $g" -ForegroundColor Green
            }
        } catch {
            Write-Host "   ❌ Failed to add to $g : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "`nGroups: (Skipped - none provided)" -ForegroundColor DarkGray
}

Write-Host "`nDone." -ForegroundColor Cyan
