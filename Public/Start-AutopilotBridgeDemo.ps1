function Start-AutopilotBridgeDemo {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string]$CustomProfile
    )
    #=======================================================================
    #	Block
    #=======================================================================
    Block-StandardUser
    Block-WindowsVersionNe10
    Block-PowerShellVersionLt5
    #=======================================================================
    #   Header
    #=======================================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Green "Start-AutopilotBridge"
    #=======================================================================
    #   Transcript
    #=======================================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Start-Transcript"
    $Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-AutopilotBridge.log"
    Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore
    Write-Host -ForegroundColor DarkGray "========================================================================="
    #=======================================================================
    #   Custom Profile
    #=======================================================================
    if ($CustomProfile) {
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Loading AutopilotBridge $CustomProfile Custom Profile"
    }
    else {
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Loading AutopilotBridge Default Profile"
    }
    #=======================================================================
    #   Profile OSD OSDeploy
    #=======================================================================
    if ($CustomProfile -in 'OSD','OSDeploy') {
        $Title = 'OSDeploy Autopilot Bridge'
        $DriverUpdate = $true
        $WindowsUpdate = $true
        $WindowsCapabilityRSAT = $true
        $RemoveAppx = @('CommunicationsApps','OfficeHub','People','Skype','Solitaire','Xbox','ZuneMusic','ZuneVideo')
    }
    #=======================================================================
    #	WindowsCapabilityRSAT
    #=======================================================================
    if ($WindowsCapabilityRSAT) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Windows Capability RSAT"
        $AddWindowsCapability = Get-MyWindowsCapability -Category Rsat -Detail
        foreach ($Item in $AddWindowsCapability) {
            if ($Item.State -eq 'Installed') {
                Write-Host -ForegroundColor DarkGray "$($Item.DisplayName)"
            }
            else {
                Write-Host -ForegroundColor DarkCyan "$($Item.DisplayName)"
                $Item | Add-WindowsCapability -Online -ErrorAction Ignore | Out-Null
                Break
            }
        }
    }
    #=======================================================================
    #	Remove-AppxOnline
    #=======================================================================
    if ($RemoveAppx) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Remove-AppxOnline"

        foreach ($Item in $RemoveAppx) {
            Remove-AppxOnline -Name $Item
        }
    }
    #=======================================================================
    #	DriverUpdate
    #=======================================================================
    if ($DriverUpdate) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) PSWindowsUpdate Driver Update"
        if (!(Get-Module PSWindowsUpdate -ListAvailable)) {
            try {
                Install-Module PSWindowsUpdate -Force
            }
            catch {
                Write-Warning 'Unable to install PSWindowsUpdate PowerShell Module'
                $DriverUpdate = $false
            }
        }
    }
    if ($DriverUpdate) {
        Get-WindowsUpdate -UpdateType Driver -ForceInstall -IgnoreReboot
    }
    #=======================================================================
    #	WindowsUpdate
    #=======================================================================
    if ($WindowsUpdate) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) PSWindowsUpdate Windows Update"
        if (!(Get-Module PSWindowsUpdate -ListAvailable)) {
            try {
                Install-Module PSWindowsUpdate -Force
            }
            catch {
                Write-Warning 'Unable to install PSWindowsUpdate PowerShell Module'
                $WindowsUpdate = $false
            }
        }
    }
    if ($WindowsUpdate) {
        Get-WindowsUpdate -UpdateType Software -ForceInstall -IgnoreReboot
    }
    #=======================================================================
    #	Stop-Transcript
    #=======================================================================
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Stop-Transcript"
    Stop-Transcript
    Write-Host -ForegroundColor DarkGray "========================================================================="
    #=======================================================================
}