# Inventory Scripts

This folder contains PowerShell scripts used to collect system and asset information.

---

## 📄 Get-Computer-Inventory.ps1

### Description
Collects basic computer inventory details including:
- Computer name
- Operating system
- IP address
- Disk size and free space

Useful for:
- Asset inventory
- Troubleshooting
- IT audits
- Support diagnostics

---

### How to Run

1. Open PowerShell
2. Navigate to the script location:
   ```powershell
   cd path\to\powershell-it-automation-toolkit\inventory
    .\Get-Computer-Inventory.ps1
---

## ✅ Sample Output

```text
Collecting computer inventory...

Computer Name : DESKTOP-RITKQ2C
OS            : Microsoft Windows 11 Pro
IP Address    :

Disk Information:

DeviceID SizeGB FreeGB
-------- ------ ------
C:       238.02 111.73
D:       0.33   0.3
