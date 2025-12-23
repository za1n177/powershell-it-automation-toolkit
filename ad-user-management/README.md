# Active Directory User Management

This folder contains PowerShell scripts related to:
- Creating users
- Disabling users
- Resetting passwords
- Managing group membership
---

## 📄 New-ADUser-Onboarding.ps1

### What it does
- Creates a new AD user in a specified OU
- Sets key attributes (UPN, display name, department/title)
- Enables the account
- Optionally adds the user to security groups
- Supports safe dry-run testing with `-WhatIf`

### Requirements
- RSAT / ActiveDirectory module
- Domain connectivity and permissions to create users

### Example (Dry-run)
```powershell
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

## 🧪 Lab Validation

Note: Script is designed for on-prem Active Directory; validation focused on identity lifecycle logic using Microsoft Entra ID due to lab constraints.

User lifecycle logic was validated using Microsoft Entra ID (Azure AD).

Test user created:
- Username: lab.user1
- Platform: Microsoft Entra ID
- Scope: Identity and access management concepts

Role assigned during testing: User Administrator (RBAC validation).

Azure Resource Group: rg-ad-lab
