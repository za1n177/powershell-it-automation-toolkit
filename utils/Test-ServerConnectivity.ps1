<#
.SYNOPSIS
    Tests basic connectivity to a server/host.

.DESCRIPTION
    Performs:
    - DNS resolution check
    - Ping test
    - TCP port test (optional)

.EXAMPLE
    .\Test-ServerConnectivity.ps1 -ComputerName "google.com"
    .\Test-ServerConnectivity.ps1 -ComputerName "fileserver01" -Port 445

.NOTES
    Author: Zaini
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ComputerName,

    [Parameter(Mandatory = $false)]
    [int]$Port
)

Write-Host "Testing connectivity to: $ComputerName" -ForegroundColor Cyan
Write-Host "----------------------------------------"

# 1) DNS Resolution
Write-Host "1) DNS Resolution:" -ForegroundColor Yellow
try {
    $dnsResult = Resolve-DnsName $ComputerName -ErrorAction Stop
    $resolvedIP = ($dnsResult | Where-Object { $_.Type -eq "A" } | Select-Object -First 1 -ExpandProperty IPAddress)
    if (-not $resolvedIP) { $resolvedIP = "Resolved (no A record displayed)" }
    Write-Host "   ✅ Success - $resolvedIP" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed - Unable to resolve DNS" -ForegroundColor Red
}

# 2) Ping Test
Write-Host "2) Ping Test:" -ForegroundColor Yellow
if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet) {
    Write-Host "   ✅ Ping successful" -ForegroundColor Green
} else {
    Write-Host "   ❌ Ping failed (ICMP may be blocked)" -ForegroundColor Red
}

# 3) TCP Port Test (Optional)
if ($PSBoundParameters.ContainsKey("Port")) {
    Write-Host "3) TCP Port Test (Port $Port):" -ForegroundColor Yellow
    try {
        $tcpTest = Test-NetConnection -ComputerName $ComputerName -Port $Port -WarningAction SilentlyContinue
        if ($tcpTest.TcpTestSucceeded) {
            Write-Host "   ✅ Port $Port is reachable" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Port $Port is not reachable" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ❌ Port test failed" -ForegroundColor Red
    }
} else {
    Write-Host "3) TCP Port Test: (Skipped - no port provided)" -ForegroundColor DarkGray
}

Write-Host "`nDone." -ForegroundColor Cyan
