# Set paths
$reportPath = "$env:TEMP\SystemScanReport.html"
$dism = "$env:SystemRoot\System32\dism.exe"
$sfc = "$env:SystemRoot\System32\sfc.exe"

function Invoke-ExternalCommand {
    param (
        [string]$exe,
        [string[]]$commandArgs
    )
    Start-Process -FilePath $exe -ArgumentList $commandArgs -NoNewWindow -RedirectStandardOutput "stdout.txt" -RedirectStandardError "stderr.txt" -Wait
    $output = Get-Content "stdout.txt"
    $errorOutput = Get-Content "stderr.txt"
    Remove-Item "stdout.txt","stderr.txt"
    return ($output + $errorOutput) -join "<br>"
}

# Run DISM commands
$dismOutput = ""
$dismOutput += "<b>AnalyzeComponentStore:</b><br>" + (Invoke-ExternalCommand $dism '/online','/cleanup-image','/analyzecomponentstore') + "<br><br>"
$dismOutput += "<b>StartComponentCleanup:</b><br>" + (Invoke-ExternalCommand $dism '/online','/cleanup-image','/startcomponentcleanup') + "<br><br>"
$dismOutput += "<b>CheckHealth:</b><br>" + (Invoke-ExternalCommand $dism '/online','/cleanup-image','/checkhealth') + "<br><br>"
$dismOutput += "<b>ScanHealth:</b><br>" + (Invoke-ExternalCommand $dism '/online','/cleanup-image','/scanhealth') + "<br><br>"
$dismOutput += "<b>RestoreHealth:</b><br>" + (Invoke-ExternalCommand $dism '/online','/cleanup-image','/restorehealth') + "<br><br>"

# Run SFC scan
$sfcOutput = "<b>SFC Scan:</b><br>" + (Invoke-ExternalCommand $sfc '/scannow') + "<br><br>"

# Generate HTML report
$htmlContent = @"
<html>
<head><title>System Scan Report</title></head>
<body>
<h1>DISM and SFC Scan Results</h1>
<h2>DISM Output</h2>
<p>$dismOutput</p>
<h2>SFC Output</h2>
<p>$sfcOutput</p>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "Report saved to: $reportPath"

# Auto-open the report
Start-Process $reportPath

# Check if reboot is needed
$rebootNeeded = $false
if ($dismOutput -match "reboot required" -or $sfcOutput -match "reboot required") {
    $rebootNeeded = $true
}

if ($rebootNeeded) {
    $answer = Read-Host "System reboot is recommended. Do you want to reboot now? (Y/N)"
    if ($answer -eq 'Y' -or $answer -eq 'y') {
        Restart-Computer
    } else {
        Write-Host "Reboot cancelled by user."
    }
} else {
    Write-Host "No reboot is necessary."
}
