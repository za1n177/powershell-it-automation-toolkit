# Active Directory User Management

This folder contains PowerShell scripts related to:
- Creating users
- Disabling users
- Resetting passwords
- Managing group membership
---

## 📄 New-ADUser-Onboarding.ps1

### Description
Creates a new Active Directory user in a specified OU, sets basic attributes, enables the account, and optionally adds the user to groups.

### Requirements
- RSAT / ActiveDirectory PowerShell module
- Domain access and permissions to create users

### Example
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
  -ForceChangePasswordAtLogon
