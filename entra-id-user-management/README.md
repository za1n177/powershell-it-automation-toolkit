# Entra ID – User to Group Assignment Automation (PowerShell)

Enterprise-ready PowerShell automation to safely assign Microsoft Entra ID (Azure AD) users to security or Microsoft 365 groups using Microsoft Graph.

Built with **idempotency**, **WhatIf safety**, and **production best practices** in mind.

---

## 🚀 Features

- Assign users to **multiple groups** in one run
- Supports **UPN, Group Name, or Group ID**
- Built-in **WhatIf (dry run)** support
- Idempotent (safe to re-run, skips existing members)
- Handles duplicate display names safely
- Clear console output (success / skip / failure)
- Microsoft Graph SDK (modern & supported)

---

## 📁 Folder Structure

```text
entra-id-user-management/
├── EntraUserToGroups.ps1
├── Entra-User-Onboarding.ps1
├── README.md
└── screenshots/
    ├── 01-graph-connected.png
    ├── 02-get-mguser-validation.png
    ├── 03-whatif-run.png
    └── 04-groups-added-success.png

🔐 Prerequisites
	•	PowerShell 5.1+ or PowerShell 7+
	•	Microsoft Graph PowerShell SDK
	•	Entra ID role:
	•	User Administrator or
	•	Groups Administrator
	•	Internet access to Microsoft Graph

Install Graph SDK (once):

Install-Module Microsoft.Graph -Scope CurrentUser


🔑 Required Microsoft Graph Permissions

Delegated permissions:

User.Read.All
Group.ReadWrite.All
Directory.ReadWrite.All

Connect with correct scopes:

Disconnect-MgGraph
Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All","Directory.ReadWrite.All"

🧪 Usage Examples

1️⃣ Safe test (recommended)

.\EntraUserToGroups.ps1 `
  -UserPrincipalName "lab.user1@tenant.onmicrosoft.com" `
  -GroupIds "GUID1","GUID2" `
  -WhatIf

2️⃣ Production run

.\EntraUserToGroups.ps1 `
  -UserPrincipalName "lab.user1@tenant.onmicrosoft.com" `
  -GroupIds "GUID1","GUID2"

🖼 Screenshots (Proof of Run)
	1.	Graph context & scopes
	2.	User lookup validation
	3.	WhatIf (dry run)
	4.	Successful group assignment

📂 See /screenshots folder.

⚠️ Common Issues

403 Forbidden (Get-MgUser / Get-MgGroup)

Cause: Missing permissions
Fix: Reconnect with correct scopes and verify admin role.

⸻

Tenant not found (AADSTS90002)

Cause: Domain used instead of Tenant GUID
Fix: Use Directory ID from Azure Portal → Entra ID → Overview.

⸻

“Already exists” error

Meaning: User is already a member
Status: Safe to ignore (idempotent behavior)

⸻

✅ Best Practices
	•	Always run with -WhatIf first
	•	Prefer Group IDs in production
	•	Safe to re-run automation
	•	Store scripts in version control
	•	Use logging for large environments

⸻

📄 License

MIT License – free to use, modify, and distribute.

---

# ✅ PART 2 — PRO VERSION ROADMAP (FOR GITHUB + SALES)

Add this section at the **bottom of README** or as `ROADMAP.md`:

```md
## 🧭 Roadmap (Pro Version)

Planned enhancements:
- Bulk onboarding via CSV
- Optional license assignment (M365 / EMS / E5)
- Logging to CSV / JSON
- Error summary report
- Non-interactive (app registration) mode
- CI/CD friendly execution

Interested? Open an issue or contact the author.
