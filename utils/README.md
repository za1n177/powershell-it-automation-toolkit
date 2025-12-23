# Utility Scripts

General helper scripts used for:
- Connectivity checks
- Log review
- Troubleshooting common IT issues
---

## 📄 Test-ServerConnectivity.ps1

### Description
Tests:
- DNS resolution
- Ping connectivity
- Optional TCP port reachability

### Examples
```powershell
# Basic checks
.\Test-ServerConnectivity.ps1 -ComputerName "google.com"

# Check SMB port (445)
.\Test-ServerConnectivity.ps1 -ComputerName "fileserver01" -Port 445

# Check RDP port (3389)
.\Test-ServerConnectivity.ps1 -ComputerName "10.0.0.10" -Port 3389
