<#
.SYNOPSIS
Add an Entra ID user to one or more Entra ID groups (by Group DisplayName or GroupId).

.DESCRIPTION
- Supports -Groups (display names) and/or -GroupIds (GUIDs)
- Idempotent: checks membership first; skips if already a member
- Supports -WhatIf for dry-run
- Optional logging to a file

.EXAMPLE
.\Add-EntraUserToGroups.ps1 -UserPrincipalName "lab.user1@contoso.onmicrosoft.com" -Groups "M365 Users","IT Helpdesk" -WhatIf

.EXAMPLE
.\Add-EntraUserToGroups.ps1 -UserPrincipalName "lab.user1@contoso.onmicrosoft.com" -GroupIds "7fdd30cd-888a-4828-b4a2-254bed2a8169","bcafecc7-21e1-4920-912c-62dcf018c44b"
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
    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [string[]]$Scopes = @("User.Read.All","Group.ReadWrite.All"),

    [Parameter(Mandatory = $false)]
    [switch]$ForceConnect,

    [Parameter(Mandatory = $false)]
    [string]$LogPath
)

function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("INFO","WARN","ERROR")][string]$Level="INFO"
    )

    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts][$Level] $Message"

    if ($Level -eq "ERROR") { Write-Host $line -ForegroundColor Red }
    elseif ($Level -eq "WARN") { Write-Host $line -ForegroundColor Yellow }
    else { Write-Host $line -ForegroundColor Cyan }

    if ($LogPath) {
        try { Add-Content -Path $LogPath -Value $line -ErrorAction Stop } catch {}
    }
}

function Ensure-GraphConnection {
    $ctx = $null
    try { $ctx = Get-MgContext -ErrorAction SilentlyContinue } catch {}

    $needConnect = $ForceConnect -or -not $ctx -or -not $ctx.TenantId

    if ($needConnect) {
        Write-Log "Not connected to Microsoft Graph. Connecting now..." "WARN"

        if ($TenantId) {
            Connect-MgGraph -TenantId $TenantId -Scopes $Scopes | Out-Null
        } else {
            Connect-MgGraph -Scopes $Scopes | Out-Null
        }

        $ctx = Get-MgContext
    }

    $who = if ($ctx.Account) { $ctx.Account } else { "WAM session (account hidden)" }
    Write-Log ("Connected as: {0} | Tenant: {1}" -f $who, $ctx.TenantId) "INFO"
    return $ctx
}

function Resolve-User {
    param([Parameter(Mandatory=$true)][string]$Upn)

    try {
        # UPN works as -UserId in Graph cmdlets
        return Get-MgUser -UserId $Upn -Property Id,DisplayName,UserPrincipalName -ErrorAction Stop
    } catch {
        throw "User not found or cannot be read: $Upn"
    }
}

function Resolve-GroupById {
    param([Parameter(Mandatory=$true)][string]$Id)
    try {
        return Get-MgGroup -GroupId $Id -Property Id,DisplayName -ErrorAction Stop
    } catch {
        throw "Group not found by Id: $Id"
    }
}

function Resolve-GroupByName {
    param([Parameter(Mandatory=$true)][string]$Name)

    # Escape single quotes for OData
    $safe = $Name.Replace("'","''")

    # Exact match first
    $exact = Get-MgGroup -Filter "displayName eq '$safe'" -ConsistencyLevel eventual -All -ErrorAction SilentlyContinue
    if ($exact -and $exact.Count -eq 1) { return $exact[0] }
    if ($exact -and $exact.Count -gt 1) {
        throw "Multiple groups found with the same DisplayName: '$Name'. Use -GroupIds instead."
    }

    # Fallback: startsWith
    $starts = Get-MgGroup -Filter "startsWith(displayName,'$safe')" -ConsistencyLevel eventual -All -ErrorAction SilentlyContinue
    if ($starts -and $starts.Count -eq 1) { return $starts[0] }
    if ($starts -and $starts.Count -gt 1) {
        $names = ($starts | Select-Object -First 5 | ForEach-Object { $_.DisplayName }) -join ", "
        throw "Multiple groups match '$Name' (examples: $names). Use an exact name or -GroupIds."
    }

    throw "Group not found by name: '$Name'"
}

function Is-UserMemberOfGroup {
    param(
        [Parameter(Mandatory=$true)][string]$GroupId,
        [Parameter(Mandatory=$true)][string]$UserId
    )

    try {
        # Fast + simple membership check
        $check = Get-MgGroupMember -GroupId $GroupId -All -ErrorAction Stop |
                 Where-Object { $_.Id -eq $UserId } |
                 Select-Object -First 1
        return [bool]$check
    } catch {
        # Some tenants block listing members; fallback to "try add and handle already exists"
        return $false
    }
}

# ---- MAIN ----
$null = Ensure-GraphConnection

if (-not $Groups -and -not $GroupIds) {
    throw "Provide -Groups and/or -GroupIds."
}

$user = Resolve-User -Upn $UserPrincipalName
Write-Log ("Target user: {0} ({1})" -f $user.DisplayName, $user.UserPrincipalName) "INFO"

# Build target list
$targets = New-Object System.Collections.Generic.List[object]

if ($GroupIds) {
    foreach ($gid in $GroupIds) {
        $grp = Resolve-GroupById -Id $gid
        $targets.Add([pscustomobject]@{ Id = $grp.Id; DisplayName = $grp.DisplayName })
    }
}

if ($Groups) {
    foreach ($gname in $Groups) {
        $grp = Resolve-GroupByName -Name $gname
        $targets.Add([pscustomobject]@{ Id = $grp.Id; DisplayName = $grp.DisplayName })
    }
}

# De-dup by Id
$targets = $targets | Sort-Object Id -Unique

Write-Log ("Groups to process: {0}" -f $targets.Count) "INFO"
$targets | ForEach-Object { Write-Host (" - {0} [{1}]" -f $_.DisplayName, $_.Id) }

foreach ($t in $targets) {
    $groupId = $t.Id
    $groupName = $t.DisplayName

    # Idempotent: skip if already member
    if (Is-UserMemberOfGroup -GroupId $groupId -UserId $user.Id) {
        Write-Log ("SKIP (already member): {0}" -f $groupName) "WARN"
        continue
    }

    if ($PSCmdlet.ShouldProcess($user.UserPrincipalName, "Add to group '$groupName'")) {
        try {
            New-MgGroupMemberByRef -GroupId $groupId -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
            } -ErrorAction Stop | Out-Null

            Write-Log ("ADDED: {0}" -f $groupName) "INFO"
        } catch {
            # If already exists, treat as OK
            $msg = $_.Exception.Message
            if ($msg -match "added object references already exist") {
                Write-Log ("SKIP (already member): {0}" -f $groupName) "WARN"
            } else {
                Write-Log ("FAILED: {0} | {1}" -f $groupName, $msg) "ERROR"
            }
        }
    } else {
        Write-Host ("WHATIF: would add user to group '{0}'" -f $groupName) -ForegroundColor Yellow
    }
}

Write-Log "Done." "INFO"
