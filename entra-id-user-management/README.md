# Entra ID User Management

PowerShell scripts for managing users in Microsoft Entra ID (Azure AD).

## Scope
- User onboarding
- Identity lifecycle management
- Cloud IAM fundamentals

## Requirements
- Microsoft Graph PowerShell
- Entra ID tenant access

# Microsoft Entra ID – User Management Scripts

This folder contains PowerShell automation scripts for managing **Microsoft Entra ID (Azure AD)** users using **Microsoft Graph PowerShell**.

These scripts are designed for **cloud-first identity environments** and demonstrate real-world IAM automation practices.

---

## 📌 Scripts Included

### 🔹 Entra-User-Onboarding.ps1

Automates the creation of a **cloud-only Entra ID user**.

**Key features:**
- Creates a new Entra ID user
- Sets initial password and forces password change at first sign-in
- Supports safe testing using `-WhatIf`
- Optionally adds the user to Entra ID security groups
- Uses Microsoft Graph PowerShell (modern & recommended)

---

## 🧩 Requirements

- PowerShell **5.1 or 7+**
- Microsoft Graph PowerShell module
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
