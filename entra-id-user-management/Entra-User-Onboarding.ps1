<#
.SYNOPSIS
  Create a new Microsoft Entra ID (Azure AD) user and optionally add to groups.

.DESCRIPTION
  Uses Microsoft Graph PowerShell to:
   - Create a cloud-only Entra ID user
   - Set initial password and force change at next sign-in
   - Optionally add the user to one or more Entra ID groups

REQUIREMENTS
  - PowerShell 5.1+ or 7+
  - Microsoft Graph PowerShell module
      Install-Module Microsoft.Graph -Scope CurrentUser
  - Permissions (delegated):
      User.ReadWrite.All, Group.ReadWrite.All (only if adding to groups)
  - You must sign in:
      Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All"

NOTES
  Author: Zaini
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter(Mandatory = $true)]
  [string]$UserPrincipalName,             # e.g. "lab.user2@yourtenant.onmicrosoft.com"

  [Parameter(Mandatory = $true)]
  [string]$DisplayName,                   # e.g. "Lab User Two"

  [Parameter(Mandatory = $true)]
  [string]$MailNickname,                  # e.g. "lab.user2"

  [Parameter(Mandatory = $true)]
  [string]$InitialPassword,               # e.g. "P@ssw0rd!123"

  [Parameter(Mandatory = $false)]
  [string]$GivenName,

  [Parameter(Mandatory = $false)]
  [string]$Surname,

  [Parameter(Mandatory = $false)]
  [string]$JobTitle,

  [Parameter(Mandatory = $false)]
  [string]$Department,

  [Parameter(Mandatory = $false)]
  [string]$UsageLocation,                 # e.g. "SG" (needed only if you later do licensing)

  [Parameter(Mandatory = $false)]
  [string[]]$GroupIds                     # Entra Group Object IDs (not names)
)

function Assert-Module {
  param([string]$Name)
  if (-not (Get-Module -ListAvailable -Name $Name)) {
    throw "Required module '$Name' not found. Run: Install-Module $Name -Scope CurrentUser"
  }
}

try {
  Assert-Module -Name "Microsoft.Graph"

  # Load only what we need (faster, cleaner)
  Import-Module Microsoft.Graph.Users -ErrorAction Stop
  Import-Module Microsoft.Graph.Groups -ErrorAction Stop

  # Check if already connected
  $ctx = Get-MgContext
  if (-not $ctx -or -not $ctx.Account) {
    Write-Host "Not connected to Microsoft Graph. Connecting now..." -ForegroundColor Yellow
    $scopes = @("User.ReadWrite.All")
    if ($GroupIds) { $scopes += "Group.ReadWrite.All" }
    Connect-MgGraph -Scopes $scopes | Out-Null
  }

  Write-Host "Preparing user payload..." -ForegroundColor Cyan

  $passwordProfile = @{
    Password = $InitialPassword
    ForceChangePasswordNextSignIn = $true
  }

  $userBody = @{
    AccountEnabled    = $true
    DisplayName       = $DisplayName
    MailNickname      = $MailNickname
    UserPrincipalName = $UserPrincipalName
    PasswordProfile   = $passwordProfile
  }

  if ($PSBoundParameters.ContainsKey("GivenName"))    { $userBody.GivenName = $GivenName }
  if ($PSBoundParameters.ContainsKey("Surname"))      { $userBody.Surname = $Surname }
  if ($PSBoundParameters.ContainsKey("JobTitle"))     { $userBody.JobTitle = $JobTitle }
  if ($PSBoundParameters.ContainsKey("Department"))   { $userBody.Department = $Department }
  if ($PSBoundParameters.ContainsKey("UsageLocation")){ $userBody.UsageLocation = $UsageLocation }

  if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Create Entra ID user")) {
    Write-Host "Creating user: $UserPrincipalName" -ForegroundColor Cyan
    $newUser = New-MgUser -BodyParameter $userBody -ErrorAction Stop

    Write-Host "✅ User created successfully" -ForegroundColor Green
    Write-Host ("   ObjectId: {0}" -f $newUser.Id)
    Write-Host ("   UPN:      {0}" -f $newUser.UserPrincipalName)
    Write-Host ("   Name:     {0}" -f $newUser.DisplayName)

    if ($GroupIds -and $GroupIds.Count -gt 0) {
      Write-Host "`nAdding user to groups..." -ForegroundColor Cyan

      foreach ($gid in $GroupIds) {
        try {
          if ($PSCmdlet.ShouldProcess($gid, "Add user to group")) {
            # Add member by reference
            New-MgGroupMemberByRef -GroupId $gid -BodyParameter @{
              "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($newUser.Id)"
            } -ErrorAction Stop

            Write-Host "✅ Added to group: $gid" -ForegroundColor Green
          }
        } catch {
          Write-Host "❌ Failed to add to group $gid : $($_.Exception.Message)" -ForegroundColor Red
        }
      }
    } else {
      Write-Host "`n(No groups provided. Skipping group assignment.)" -ForegroundColor DarkGray
    }

    Write-Host "`nDone." -ForegroundColor Cyan
  }

} catch {
  Write-Host "`n❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
  throw
}
