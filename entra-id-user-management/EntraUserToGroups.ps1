<#
.SYNOPSIS
  Add a Microsoft Entra ID (Azure AD) user to one or more groups using Microsoft Graph PowerShell.

.DESCRIPTION
  - Resolves user by UPN
  - Resolves groups by DisplayName OR ObjectId
  - Adds user to each group (skips if already member)
  - Supports -WhatIf for safe dry-run testing

.REQUIREMENTS
  - PowerShell 5.1+ or 7+
  - Microsoft.Graph PowerShell module
  - Delegated permissions: Group.ReadWrite.All, User.Read.All (or User.ReadWrite.All)

.EXAMPLE
  .\Add-EntraUserToGroups.ps1 -UserPrincipalName "lab.user1@yourtenant.onmicrosoft.com" -Groups "IT Helpdesk","M365 Users" -WhatIf

.EXAMPLE
  .\Add-EntraUserToGroups.ps1 -UserPrincipalName "lab.user1@yourtenant.onmicrosoft.com" -GroupIds "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$UserPrincipalName,

  [Parameter(Mandatory = $false)]
  [string[]]$Groups,

  [Parameter(Mandatory = $false)]
  [string[]]$GroupIds,

  [Parameter(Mandatory = $false)]
  [switch]$ForceConnect
)

function Ensure-GraphConnection {
  param(
    [string[]]$Scopes,
    [switch]$Force
  )

  $ctx = $null
  try { $ctx = Get-MgContext -ErrorAction SilentlyContinue } catch {}

  if ($Force -or -not $ctx -or -not $ctx.Account) {
    Write-Host "Not connected to Microsoft Graph. Connecting now..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes $Scopes | Out-Null
    $ctx = Get-MgContext
  }

  Write-Host ("Connected as: {0} | Tenant: {1}" -f $ctx.Account, $ctx.TenantId) -ForegroundColor Cyan
}

function Resolve-User {
  param([string]$Upn)

  try {
    # UPN works directly as userId in Graph cmdlets
    $u = Get-MgUser -UserId $Upn -Property Id,DisplayName,UserPrincipalName -ErrorAction Stop
    return $u
  } catch {
    throw "User not found or cannot be read: $Upn"
  }
}

function Resolve-GroupByName {
  param([string]$Name)

  # Escape single quotes for OData
  $safe = $Name.Replace("'", "''")

  # Try exact match first
  $exact = Get-MgGroup -Filter "displayName eq '$safe'" -Property Id,DisplayName -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue
  if ($exact -and $exact.Count -eq 1) { return $exact[0] }
  if ($exact -and $exact.Count -gt 1) {
    throw "Multiple groups found with the same DisplayName: '$Name'. Use -GroupIds instead."
  }

  # Fallback: startsWith
  $starts = Get-MgGroup -Filter "startsWith(displayName,'$safe')" -Property Id,DisplayName -ConsistencyLevel eventual -CountVariable c2 -ErrorAction SilentlyContinue
  if ($starts -and $starts.Count -eq 1) { return $starts[0] }
  if ($starts -and $starts.Count -gt 1) {
    $names = ($starts | Select-Object -First 5 | ForEach-Object { $_.DisplayName }) -join ", "
    throw "Multiple groups match '$Name' (example matches: $names). Use an exact name or -GroupIds."
  }

  throw "Group not found by name: '$Name'"
}

function Resolve-GroupById {
  param([string]$Id)
  try {
    return Get-MgGroup -GroupId $Id -Property Id,DisplayName -ErrorAction Stop
  } catch {
    throw "Group not found by Id: $Id"
  }
}

function Is-UserMemberOfGroup {
  param(
    [string]$GroupId,
    [string]$UserId
  )

  # Lightweight membership check: try to fetch the member reference by ID
  try {
    $null = Get-MgGroupMember -GroupId $GroupId -DirectoryObjectId $UserId -ErrorAction Stop
    return $true
  } catch {
    return $false
  }
}

# --- Validate input ---
if ((-not $Groups -or $Groups.Count -eq 0) -and (-not $GroupIds -or $GroupIds.Count -eq 0)) {
  throw "You must supply either -Groups (names) or -GroupIds (object IDs)."
}

$requiredScopes = @("Group.ReadWrite.All","User.Read.All")

Ensure-GraphConnection -Scopes $requiredScopes -Force:$ForceConnect

$user = Resolve-User -Upn $UserPrincipalName
Write-Host ("Target user: {0} ({1})" -f $user.DisplayName, $user.UserPrincipalName) -ForegroundColor Green

# Build group targets
$targets = New-Object System.Collections.Generic.List[object]

if ($Groups) {
  foreach ($g in $Groups) {
    $grp = Resolve-GroupByName -Name $g
    $targets.Add([pscustomobject]@{ Id = $grp.Id; DisplayName = $grp.DisplayName })
  }
}

if ($GroupIds) {
  foreach ($gid in $GroupIds) {
    $grp = Resolve-GroupById -Id $gid
    $targets.Add([pscustomobject]@{ Id = $grp.Id; DisplayName = $grp.DisplayName })
  }
}

# De-dup by GroupId
$targets = $targets | Sort-Object Id -Unique

Write-Host ("Groups to process: {0}" -f ($targets.Count)) -ForegroundColor Cyan
$targets | ForEach-Object { Write-Host (" - {0} [{1}]" -f $_.DisplayName, $_.Id) }

# Process adds
foreach ($t in $targets) {
  $groupId = $t.Id
  $groupName = $t.DisplayName

  if (Is-UserMemberOfGroup -GroupId $groupId -UserId $user.Id) {
    Write-Host ("SKIP (already member): {0}" -f $groupName) -ForegroundColor DarkYellow
    continue
  }

  if ($PSCmdlet.ShouldProcess("$($user.UserPrincipalName)", "Add to group '$groupName'")) {
    try {
      New-MgGroupMember -GroupId $groupId -DirectoryObjectId $user.Id -ErrorAction Stop | Out-Null
      Write-Host ("ADDED: {0}" -f $groupName) -ForegroundColor Green
    } catch {
      Write-Host ("FAILED: {0} | {1}" -f $groupName, $_.Exception.Message) -ForegroundColor Red
    }
  } else {
    Write-Host ("WHATIF: would add user to group '{0}'" -f $groupName) -ForegroundColor Yellow
  }
}

Write-Host "Done." -ForegroundColor Cyan
