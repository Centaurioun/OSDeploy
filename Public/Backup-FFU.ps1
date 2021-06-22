function Backup-FFU {
    [CmdletBinding()]
    param ()

    & "$($MyInvocation.MyCommand.Module.ModuleBase)\GUI\CaptureFFU.ps1"
}