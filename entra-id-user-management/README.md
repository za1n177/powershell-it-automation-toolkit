# Entra ID User → Group Assignment (PowerShell + Microsoft Graph)

Automate adding a Microsoft Entra ID (Azure AD) user to one or more groups using Microsoft Graph PowerShell.

✅ Supports:
- Add by **Group Names** or **Group IDs**
- `-WhatIf` safety mode
- Idempotent behavior (skip if already a member)
- Clear console output (success / skip / failed)

---

## 📌 What this does

You run one command and it will:
1. Connect to Microsoft Graph (interactive login)
2. Resolve the target user by UPN
3. Resolve groups (by name or by ID)
4. Add the user to each group (or skip if already in)

---

## 📂 Folder structure

entra-id-user-management/
├─ EntraUserToGroups.ps1
├─ Entra-User-Onboarding.ps1
├─ README.md
└─ screenshots/
├─ 01-connect-mggraph-context.png
├─ 02-get-mguser-validation.png
├─ 03-whatif-run.png
├─ 04-groups-added-success.png
└─ 05-idempotent-retry.png

yaml
Copy code

---

## 🔐 Prerequisites

### 1) PowerShell
- Windows PowerShell 5.1+ or PowerShell 7+

### 2) Microsoft Graph PowerShell
Install once:
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
3) Sign-in / roles
Your account must have permission to:

Read users

Read groups

Add group members

In labs, User Administrator + Groups Administrator is usually enough.

✅ Required Microsoft Graph permissions (Scopes)
This script uses delegated permissions via interactive login.

Recommended:

User.Read.All

Group.ReadWrite.All

Directory.ReadWrite.All

Example connect:

powershell
Copy code
Connect-MgGraph -TenantId "<YOUR_TENANT_ID>" -Scopes `
  "User.Read.All","Group.ReadWrite.All","Directory.ReadWrite.All"
🚀 Quick start
Option A — Add user to groups by Group Name
powershell
Copy code
.\EntraUserToGroups.ps1 `
  -UserPrincipalName "lab.user1@yourtenant.onmicrosoft.com" `
  -Groups "M365 Users","IT Helpdesk" `
  -WhatIf
Remove -WhatIf to execute for real.

Option B — Add user to groups by Group ID (recommended for production)
powershell
Copy code
.\EntraUserToGroups.ps1 `
  -UserPrincipalName "lab.user1@yourtenant.onmicrosoft.com" `
  -GroupIds "7fdd30cd-888a-4828-b4a2-254bed2a8169","bcafecc7-21e1-4920-912c-62dcf018c44b" `
  -WhatIf
🔎 How to find Group IDs
Search by exact display name:

powershell
Copy code
Get-MgGroup -Filter "displayName eq 'M365 Users'" -ConsistencyLevel eventual -All |
  Select DisplayName, Id
🧪 Verification commands
Check your current tenant + scopes:

powershell
Copy code
Get-MgContext | Select TenantId, Scopes
Confirm the user exists:

powershell
Copy code
Get-MgUser -UserId "lab.user1@yourtenant.onmicrosoft.com" |
  Select DisplayName, UserPrincipalName, Id
🖼️ Screenshots (proof of run)
1) Graph context + scopes

2) User lookup validation

3) Safe test (-WhatIf)

4) Successful add

5) Re-run (idempotent / already exists)

🧠 Common issues
403 Forbidden (Get-MgUser / Get-MgGroup)
You’re connected, but your account/scopes don’t allow reading directory objects.
Fix:

Reconnect with proper scopes:

powershell
Copy code
Disconnect-MgGraph
Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All","Directory.ReadWrite.All"
Ensure your account has the right Entra admin role.

“Tenant not found” (AADSTS90002)
You used a domain name instead of the Tenant GUID.
Fix:

Use Azure Portal → Entra ID → Overview → Tenant ID

Or the “Directories” screen → Directory ID

✅ Notes / Best practices
Prefer Group IDs in production to avoid duplicates.

Always run with -WhatIf first.

If you see “already exist” errors, it means the user is already a member (safe to ignore).

## 📄 License
MIT License – free to use, modify, and distribute.

