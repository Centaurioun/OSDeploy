#=======================================================================
#   Load Assemblies
#=======================================================================
# Assign current script directory to a global variable
$Global:MyScriptDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

# Load presentationframework and Dlls for the MahApps.Metro theme
[System.Reflection.Assembly]::LoadWithPartialName("presentationframework") | Out-Null
[System.Reflection.Assembly]::LoadFrom("$Global:MyScriptDir\assembly\MahApps.Metro.dll") | Out-Null
[System.Reflection.Assembly]::LoadFrom("$Global:MyScriptDir\assembly\System.Windows.Interactivity.dll") | Out-Null
#=======================================================================
#   Set PowerShell Window Title
#=======================================================================
$host.ui.RawUI.WindowTitle = "PowerShell Start-DismImage"
#=======================================================================
#   Test-InWinPE
#=======================================================================
function Test-InWinPE {
    return Test-Path -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlset\Control\MiniNT
}
#=======================================================================
#   LoadForm
#=======================================================================
function LoadForm {
    [CmdletBinding()]
    Param(
     [Parameter(Mandatory = $False, Position = 1)]
     [string]$XamlPath
    )

    # Import the XAML code
    [xml]$Global:xmlWPF = Get-Content -Path $XamlPath

    # Add WPF and Windows Forms assemblies
    Try {
        Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase, system.windows.forms
    } 
    Catch {
        Throw "Failed to load Windows Presentation Framework assemblies."
    }

    #Create the XAML reader using a new XML node reader
    $Global:xamGUI = [Windows.Markup.XamlReader]::Load((new-object System.Xml.XmlNodeReader $xmlWPF))

    #Create hooks to each named object in the XAML
    $xmlWPF.SelectNodes("//*[@Name]") | foreach {
        Set-Variable -Name ($_.Name) -Value $xamGUI.FindName($_.Name) -Scope Global
    }
}
LoadForm -XamlPath (Join-Path $Global:MyScriptDir 'DismImage.xaml')
#=======================================================================
#   GlobalVariables
#=======================================================================
$Global:DismImage = @{
    BiosVersion = Get-MyBiosVersion
    CaptureDrives = Get-Disk.fixed | Where-Object {$_.IsBoot -eq $false}
    Manufacturer = Get-MyComputerManufacturer -Brief
    Model = Get-MyComputerModel -Brief
    RegCurrentVersion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    SerialNumber = Get-MyBiosSerialNumber -Brief
    Title = 'DismImage'
    Version = Get-Module -Name OSDeploy | Sort-Object -Property Version | Select-Object -ExpandProperty Version -Last 1
}
#=======================================================================
#   Subtitle
#=======================================================================
$Global:DismImage.ProductName = ($Global:DismImage.RegCurrentVersion).ProductName

if ($Global:DismImage.RegCurrentVersion.DisplayVersion -gt 0) {
    $Global:DismImage.DisplayVersion = ($Global:DismImage.RegCurrentVersion).DisplayVersion
}
else {
    $Global:DismImage.DisplayVersion = ($Global:DismImage.RegCurrentVersion).ReleaseId
}
$Global:DismImage.BuildNumber = "$($Global:DismImage.RegCurrentVersion.CurrentBuild).$($Global:DismImage.RegCurrentVersion.UBR)"
#=======================================================================
#   Content
#=======================================================================
$LabelTitle.Content = $Global:DismImage.Title
$LabelVersion.Content = $Global:DismImage.Version
$LabelManufacturer.Content = $Global:DismImage.Manufacturer
$LabelModel.Content = $Global:DismImage.Model
$LabelSerialNumber.Content = $Global:DismImage.SerialNumber
$LabelSubtitle.Content = "$($Global:DismImage.ProductName) $($Global:DismImage.DisplayVersion) ($($Global:DismImage.BuildNumber))"
$LabelBiosVersion.Content = $Global:DismImage.BiosVersion
$DismDescriptionTextbox.Text = "$($Global:DismImage.Manufacturer) $($Global:DismImage.Model) $($Global:DismImage.SerialNumber)"
#=======================================================================
#   Right Side TPM
#=======================================================================
try {
    $TpmSpecVersion = (Get-CimInstance -Namespace "root\CIMV2\Security\MicrosoftTPM" -ClassName Win32_Tpm).SpecVersion
}
catch {}

if ($TpmSpecVersion -match '2.0') {
    $LabelTpmVersion.Content = "TPM: 2.0"
    $LabelTpmVersion.Background = "Green"
}
elseif ($TpmSpecVersion -match '1.2') {
    $LabelTpmVersion.Content = "TPM: 1.2"
    $LabelTpmVersion.Background = "Red"
}
else {
    $LabelTpmVersion.Visibility = "Collapsed"
}
#=======================================================================
#   Visibility Functions
#=======================================================================
function Hide-DismCompress {
    $DismCompressLabel.Visibility = "Collapsed"
    $DismCompressCombobox.Visibility = "Collapsed"
}
function Hide-DismDescription {
    $DismDescriptionLabel.Visibility = "Collapsed"
    $DismDescriptionTextbox.Visibility = "Collapsed"
}
function Hide-DismDestination {
    $DismDestinationLabel.Visibility = "Collapsed"
    $DismDestinationCombobox.Visibility = "Collapsed"
}
function Hide-DismName {
    $DismNameLabel.Visibility = "Collapsed"
    $DismNameTextbox.Visibility = "Collapsed"
}
function Hide-DismSource {
    $DismSourceLabel.Visibility = "Collapsed"
    $DismSourceCombobox.Visibility = "Collapsed"
}
function Show-DismCompress {
    $DismCompressLabel.Visibility = "Visible"
    $DismCompressCombobox.Visibility = "Visible"
}
function Show-DismDescription {
    $DismDescriptionLabel.Visibility = "Visible"
    $DismDescriptionTextbox.Visibility = "Visible"
    $DismDescriptionTextbox.Text = "$($Global:DismImage.Manufacturer) $($Global:DismImage.Model) $($Global:DismImage.SerialNumber)"
}
function Show-DismDestination {
    $DismDestinationLabel.Visibility = "Visible"
    $DismDestinationCombobox.Visibility = "Visible"
}
function Show-DismName {
    $DismNameLabel.Visibility = "Visible"
    $DismNameTextbox.Visibility = "Visible"
}
function Show-DismSource {
    $DismSourceLabel.Visibility = "Visible"
    $DismSourceCombobox.Visibility = "Visible"
}
#=======================================================================
#   DismAction Defaults
#=======================================================================
$DismActionLabel.Content = "Dism.exe"

$DismActionCombobox.Items.Add('Command Line Help') | Out-Null
$DismActionCombobox.Items.Add('/Apply-FFU') | Out-Null
$DismActionCombobox.Items.Add('/Capture-FFU') | Out-Null

$DismActionCombobox.SelectedIndex = "0"
$DismCommandTextbox.Text = "Dism.exe /?"
#=======================================================================
#   DismAction add_SelectionChanged
#=======================================================================
$DismActionCombobox.add_SelectionChanged({
    Hide-DismSource
    Hide-DismDestination
    Hide-DismName
    Hide-DismDescription
    Hide-DismCompress

    Start-DismAction
})
#=======================================================================
#   DismAction Start-DismAction
#=======================================================================
function Start-DismAction {
    if ($DismActionCombobox.SelectedValue -eq 'Command Line Help') {
        $DismCommandTextbox.Text = "Dism.exe /?"
        $DismSourceCombobox.Items.Clear()
        $DismDestinationCombobox.Items.Clear()
    }
    if ($DismActionCombobox.SelectedValue -eq '/Apply-FFU') {
        $StartButton.Visibility = "Collapsed"
        $DismCommandTextbox.Text = "Dism.exe /Apply-FFU /?"


        $DismSourceLabel.Content = "/ImageFile:"
        $DismSourceCombobox.Items.Clear()
        Show-DismSource
    }
    if ($DismActionCombobox.SelectedValue -eq '/Capture-FFU') {
        $StartButton.Visibility = "Collapsed"
        $DismCommandTextbox.Text = "Dism.exe /Capture-FFU /?"
        $DismCompressLabel.Content = "/Compress:"
        $DismCompressCombobox.Items.Clear()
        $DismCompressCombobox.Items.Add('Default') | Out-Null
        $DismCompressCombobox.Items.Add('None') | Out-Null
        $DismCompressCombobox.SelectedIndex = "0"
        Start-SourceAction
    }
}
#=======================================================================
#   SourceAction
#=======================================================================
function Start-SourceAction {
    if ($DismActionCombobox.SelectedValue -eq '/Apply-FFU') {

    }
    if ($DismActionCombobox.SelectedValue -eq '/Capture-FFU') {
        $DismSourceLabel.Content = "/CaptureDrive:"
        $DismSourceCombobox.Items.Clear()

        Show-DismSource

        if (!($Global:DismImage.CaptureDrives)) {
            $DismSourceCombobox.Foreground = "Red"
            $DismSourceCombobox.IsEnabled = "False"
            $DismSourceCombobox.SelectedIndex = "0"
            $DismSourceCombobox.Items.Add("No disks are present that can be captured") | Out-Null
            $DismSourceCombobox.Items.Add("WinPE is required to capture an FFU") | Out-Null
        }
        else {
            $Global:ArrayOfDiskNumbers = @()
            $Global:DismImage.CaptureDrives | foreach {
                $DismSourceCombobox.Items.Add("\\.\PhysicalDrive$($_.DiskNumber) [$($_.BusType) $($_.MediaType) - $($_.FriendlyName)]") | Out-Null
                $Global:ArrayOfDiskNumbers += $_.Number
            }
        }
    }
}
#=======================================================================
#   DismSource add_SelectionChanged
#=======================================================================
$DismSourceCombobox.add_SelectionChanged({
    Start-DestinationAction
})
#=======================================================================
#   DismDestination Start-DestinationAction
#=======================================================================
function Start-DestinationAction {
    if ($DismActionCombobox.SelectedValue -eq '/Apply-FFU') {

    }
    if ($DismActionCombobox.SelectedValue -eq '/Capture-FFU') {
        #Determine the Selected Disk information
        $Global:DismImage.SourceDiskNumber = (Get-Disk.fixed | Where-Object { $_.Number -eq $Global:ArrayOfDiskNumbers[$DismSourceCombobox.SelectedIndex] }).DiskNumber
        $Global:DismImage.PhysicalDrive = "\\.\PhysicalDrive$($Global:DismImage.SourceDiskNumber)"

        $DismCommandTextbox.Text = "Dism.exe /Capture-FFU /CaptureDrive:$($Global:DismImage.PhysicalDrive) /?"

        $DismDestinationLabel.Content = "/ImageFile:"
        $DismDestinationCombobox.Items.Clear()

        $Global:DismImage.ApplyDrives = @()
        $Global:DismImage.ApplyDrives = Get-Disk.storage | Where-Object {$_.DiskNumber -ne $Global:DismImage.SourceDiskNumber}

        Show-DismDestination

        if (!($Global:DismImage.ApplyDrives)) {
            $DismDestinationCombobox.Foreground = "Red"
            $DismDestinationCombobox.IsEnabled = "False"
            $DismDestinationCombobox.SelectedIndex = "0"
            $DismDestinationCombobox.Items.Add("No drives are available to save the FFU file") | Out-Null
        }
        else {
            #Dism Name
            $Global:DismImage.Name = "disk$($Global:DismImage.SourceDiskNumber)"
            $DismNameTextbox.Text = $Global:DismImage.Name

            foreach ($DestinationDrive in $Global:DismImage.ApplyDrives) {
                if ($DestinationDrive.DriveLetter -gt 0) {
                    $Global:DismImage.ImageFile = "$($DestinationDrive.DriveLetter):\DismImage\$($Global:DismImage.Manufacturer)\$($Global:DismImage.Model)\$($Global:DismImage.SerialNumber)_$($Global:DismImage.Name).ffu"
                    $DismDestinationCombobox.Items.Add($Global:DismImage.ImageFile) | Out-Null
                }
            }
            $DismDestinationCombobox.SelectedIndex = 0
            $DismDestinationCombobox.IsEditable = "True"

            Show-DismName
            Show-DismDescription
            Show-DismCompress
            Set-DismCommandCaptureFFU
            $StartButton.Visibility = "Visible"
        }
    }
}
#=======================================================================
#   Set-DismCommandCaptureFFU
#=======================================================================
function Set-DismCommandCaptureFFU {
    $DismCommandTextbox.Text = "Dism.exe /Capture-FFU /CaptureDrive:$($Global:DismImage.PhysicalDrive) /ImageFile=`"$($DismDestinationCombobox.Text)`" /Name:`"$($DismNameTextbox.Text)`" /Description:`"$($DismDescriptionTextbox.Text)`" /Compress:$($DismCompressCombobox.SelectedValue)"
}
#=======================================================================
#   add_SelectionChanged
#=======================================================================
$DismDestinationCombobox.add_SelectionChanged({
    if ($DismActionCombobox.SelectedValue -eq '/Capture-FFU') {
        Set-DismCommandCaptureFFU
    }
})
$DismDestinationCombobox.add_DropDownClosed({
    Set-DismCommandCaptureFFU
})
$DismDestinationCombobox.add_KeyUp({
    Set-DismCommandCaptureFFU
})
$DismNameTextbox.add_KeyUp({
    Set-DismCommandCaptureFFU
})
$DismDescriptionTextbox.add_KeyUp({
    Set-DismCommandCaptureFFU
})
#=======================================================================
#   StartButton
#=======================================================================
$StartButton.add_Click({
    $Global:DismParams = @{}

    if ($DismActionCombobox.SelectedValue -eq 'Command Line Help') {
        Start-Process PowerShell.exe -ArgumentList '-NoExit','-NoLogo','Dism.exe','/?'
    }

    $xamGUI.Close()


    if ($DismActionCombobox.SelectedValue -eq '/Capture-FFU') {
        $ParentDirectory = Split-Path $DismDestinationCombobox.Text -Parent -ErrorAction Stop

        if (Test-Path $DismDestinationCombobox.Text) {
            Write-Warning "ImageFile already exists.  Rename the ImageFile and try again"; Break
        }

        if (!(Test-Path "$ParentDirectory")) {
            Try {New-Item -Path $ParentDirectory -ItemType Directory -Force -ErrorAction Stop}
            Catch {Write-Warning "ImageFile appears to be in a Read Only directory.  Try another Path"; Break}
        }

        if (-NOT (Test-InWinPE)) {
            Write-Warning "Dism.exe /Capture-FFU requires WinPE"
            #Break
        }

        $Global:DismParams = @{
            Dism = '/Capture-FFU'
            CaptureDrive = $Global:DismImage.PhysicalDrive
            ImageFile = $DismDestinationCombobox.Text
            Name = $DismNameTextbox.Text
            Description = $DismDescriptionTextbox.Text
            Compress = $DismCompressCombobox.SelectedValue
        }

        Get-OSDPower -Property High
        Start-Process PowerShell.exe -Wait -WorkingDirectory $ParentDirectory -ArgumentList '-NoExit','-NoLogo','Dism.exe','/Capture-FFU',"/CaptureDrive:'$($Global:DismParams.CaptureDrive)'","/ImageFile:'$($Global:DismParams.ImageFile)'","/Name:'$($Global:DismParams.Name)'","/Description:'$($Global:DismParams.Description)'","/Compress:$($Global:DismParams.Compress)"
        Get-OSDPower -Property Balanced
        
        if (Test-Path $DismDestinationCombobox.Text) {
            Get-WindowsImage -ImagePath $DismDestinationCombobox.Text -ErrorAction Ignore
        }
    }
})
#=======================================================================
#   ShowDialog
#=======================================================================
$xamGUI.ShowDialog() | Out-Null
#=======================================================================