<#
.SYNOPSIS
    UWF Control Script for Windows 10 LTSC
    Admin rights required.
#>

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Please run this script as Administrator!" -ForegroundColor Red
    pause
    exit
}

function Show-UWFStatus {
    Write-Host "`n--- CURRENT UWF CONFIGURATION ---" -ForegroundColor Cyan

    # Get filter state via WMI
    $filter = Get-WmiObject -Namespace "root\standardcimv2\embedded" -Class UWF_Filter -ErrorAction SilentlyContinue
    if ($filter) {
        $currentState = if ($filter.CurrentEnabled) { "ENABLED" } else { "DISABLED" }
        $nextState = if ($filter.NextEnabled) { "ENABLED" } else { "DISABLED" }
        $currentColor = if ($filter.CurrentEnabled) { "Green" } else { "Yellow" }
        $nextColor = if ($filter.NextEnabled) { "Green" } else { "Yellow" }

        Write-Host "Filter Status:" -ForegroundColor Cyan
        Write-Host " - Current session: $currentState" -ForegroundColor $currentColor
        Write-Host " - Next session:    $nextState" -ForegroundColor $nextColor
    } else {
        Write-Host "Filter Status: Unable to read UWF_Filter state." -ForegroundColor Yellow
    }

    # Keep original raw config lines visible too
    uwfmgr get-config | Select-String "Current:", "Next Session:" | Out-String | Write-Host
    
    # Get volume states via WMI
    $volumes = Get-WmiObject -Namespace "root\standardcimv2\embedded" -Class UWF_Volume
    Write-Host "Volume Protection Status:" -ForegroundColor Cyan
    if ($volumes) {
        foreach ($v in $volumes) {
            $state = if ($v.Protected) { "PROTECTED" } else { "NOT PROTECTED" }
            $color = if ($v.Protected) { "Green" } else { "Gray" }
            Write-Host " - Drive $($v.DriveLetter) is $state" -ForegroundColor $color
        }
    } else {
        Write-Host " - No volumes configured in UWF." -ForegroundColor Gray
    }
    Write-Host "----------------------------------`n"
}

do {
    Show-UWFStatus
    Write-Host "1 - Enable UWF Filter (Next boot)"
    Write-Host "2 - Disable UWF Filter (Next boot)"
    Write-Host "3 - Add Volume to protection (e.g. C:)"
    Write-Host "4 - Remove Volume from protection"
    Write-Host "5 - Restart Computer now"
    Write-Host "Q - Quit"
    
    $choice = Read-Host "`nSelect an option"

    switch ($choice) {
        "1" { 
            uwfmgr filter enable 
            Write-Host "Filter enabled for next session." -ForegroundColor Green
        }
        "2" { 
            uwfmgr filter disable 
            Write-Host "Filter disabled for next session." -ForegroundColor Yellow
        }
        "3" {
            $drive = Read-Host "Enter drive letter to protect (e.g. C:)"
            if ($drive -notmatch ":$") { $drive += ":" }
            uwfmgr volume protect $drive
        }
        "4" {
            $drive = Read-Host "Enter drive letter to unprotect (e.g. C:)"
            if ($drive -notmatch ":$") { $drive += ":" }
            uwfmgr volume unprotect $drive
        }
        "5" {
            Write-Host "Restarting..." -ForegroundColor Red
            Restart-Computer
            exit
        }
    }
} while ($choice -ne "Q")