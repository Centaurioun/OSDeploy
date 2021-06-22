function Backup-FFU {
    [CmdletBinding()]
    param ()

    & "$($MyInvocation.MyCommand.Module.ModuleBase)\GUI\BackupFFU.ps1"
}