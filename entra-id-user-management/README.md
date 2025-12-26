# Entra ID User to Groups Automation (PowerShell)

A **production-ready PowerShell script** to safely add Microsoft Entra ID (Azure AD) users to one or more Microsoft 365 / Security groups using **Microsoft Graph**.

Built with **safety, idempotency, and real enterprise usage** in mind.

---

## 🚀 Features

- ✅ Add a user to **multiple Entra ID groups**
- ✅ Supports **GroupIds (recommended)** and Group Display Names
- ✅ Safe **`-WhatIf` dry-run mode**
- ✅ Idempotent (safe to re-run; skips existing members)
- ✅ Uses **Microsoft Graph PowerShell SDK**
- ✅ Clear, audit-friendly console output
- ✅ Works with WAM (Windows Account Manager) authentication

---

## 📁 Folder Structure

entra-id-user-management/
│
├── Add-EntraUserToGroups.ps1
├── README.md
├── docs/
│   └── screenshots/
│       ├── 01-connect-graph.png
│       ├── 02-whatif-preview.png
│       ├── 03-add-success.png
│
└── examples/
├── add-by-groupid.ps1
└── add-by-groupname.ps1
---

## 🔐 Prerequisites

- Windows PowerShell 5.1+ or PowerShell 7+
- Microsoft Graph PowerShell SDK

Install if needed:
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser

🔑 Required Microsoft Graph Permissions

Delegated permissions:
	•	User.ReadWrite.All
	•	Group.ReadWrite.All
	•	Directory.ReadWrite.All

These are requested automatically during sign-in.

🔌 Connect to Microsoft Graph (Example)
Connect-MgGraph `
  -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All"

Verify connection:
Get-MgContext | Select TenantId, Scopes

🧑‍💻 Usage Examples

▶ Dry Run (Recommended)
.\Add-EntraUserToGroups.ps1 `
  -UserPrincipalName "lab.user1@tenant.onmicrosoft.com" `
  -GroupIds "GROUPID-1","GROUPID-2" `
  -WhatIf

▶ Actual Execution
.\Add-EntraUserToGroups.ps1 `
  -UserPrincipalName "lab.user1@tenant.onmicrosoft.com" `
  -GroupIds "GROUPID-1","GROUPID-2"

📌 Sample Output

Connected as: WAM session (account hidden)
Target user: Lab User One (lab.user1@tenant.onmicrosoft.com)

Groups to process: 2
 - M365 Users
 - IT Helpdesk

ADDED: M365 Users
ADDED: IT Helpdesk
Done.

Re-running the script safely:

SKIP (already member): M365 Users
SKIP (already member): IT Helpdesk
Done.

🛡 Design Principles
	•	Safe-by-default using -WhatIf
	•	Idempotent logic (no duplicate membership errors)
	•	Explicit group resolution (ID-first)
	•	Clear output for helpdesk and audit trails
	•	Microsoft Graph native (future-proof)

⸻

⚠ Common Notes
	•	If multiple groups share the same display name, use -GroupIds
	•	Always test with -WhatIf before real execution
	•	Avoid committing real tenant IDs or real user emails


