#========================================================================
# Author 	: Kevin RAHETILAHY                                          #
#========================================================================
##############################################################
#                      LOAD ASSEMBLY                         #
##############################################################
Add-Type -AssemblyName PresentationCore, PresentationFramework, System.Windows.Forms
Get-ChildItem -Recurse -Filter "*.dll" | ForEach-Object {
    Add-Type -Path $_.FullName
}
$Main = Get-ChildItem -Recurse -Filter "Main.xml"
$DialogXML = Get-ChildItem -Recurse -Filter "RestartWindow.xml"
[System.Windows.Forms.Application]::EnableVisualStyles()
##############################################################
#                      LOAD FUNCTION                         #
##############################################################

# Load MainWindow
function LoadWindow {
    param (
        [String]$FileName,
        [Switch]$XML
    )
    if ($XML) {
        $XamlLoader = [System.Xml.XmlDocument]::new()
        $XamlLoader.Load($FileName)
        [xml]$xml = $XamlLoader
        return [xml]$xml
    }
    else {
        $XamlLoader = [System.Xml.XmlDocument]::new()
        $XamlLoader.Load($FileName)
        $Reader = [System.Xml.XmlNodeReader]::new($XamlLoader)
        return [Windows.Markup.XamlReader]::Load($Reader)
    }
}

$Form = LoadWindow -FileName $Main.FullName
$xml = LoadWindow -FileName $Main.FullName -XML
$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $Form.FindName($_.Name) }
$Dialog = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($Form)
$DialogForm = LoadWindow -FileName $DialogXML.FullName
$Dialog.AddChild($DialogForm)
$xml = LoadWindow -FileName $DialogXML.FullName -XML
$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $DialogForm.FindName($_.Name) }
$settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
$settings.ColorScheme = [MahApps.Metro.Controls.Dialogs.MetroDialogColorScheme]::Theme
$observableCollection = [System.Collections.ObjectModel.ObservableCollection[Object]]::new()
$Svc = Get-Service -Name "*sql*"
$svc | ForEach-Object {
    $o = [PSCustomObject]@{
        ServiceName = $_.ServiceName
        Status = $_.Status
        PG = $False
    }
    $observableCollection.Add($o)
}
$btnCancel.Add_Click({
    $Dialog.RequestCloseAsync()
})

<#
$btnRestart.Add_Click({
    LoadingIndicatorsStatus -Enable
    $btnRestart.IsEnabled = $False
    $StopJob = Start-Job -Name "Restart Service" -ScriptBlock {
        Get-Service -Name $Using:svc.Name | Stop-Service -Force
    }
    do {
        $status = Get-Job -id $StopJob.id
    }until ($Status.State -eq "Completed")
    do {
        $Status = Get-Service -Name $svc.Name
    }until ($Status.Status -eq "Stopped")
    $StartJob = Start-Job -Name "Start Service" -ScriptBlock {
        Get-Service -Name $Using:svc.Name | Start-Service
    }
    do {
        $status = Get-Job -id $StartJob.id
    }until ($Status.State -eq "Completed")
    do {
        $Status = Get-Service -Name $svc.Name
    }until ($Status.Status -eq "Running")
    LoadingIndicatorsStatus
    $btnRestart.IsEnabled = $True
    $RestartLabel.Content = "Service Restarted"

})
#>
function rs {

    $btnRestart.IsEnabled = $False
    $Job = Start-Job -ScriptBlock { Ping 1.1.1.1 }
    while($job.Finished.WaitOne(200)){
        [Windows.Forms.Application]::DoEvents()
    }
    $ArcsStyle.IsActive = $False
    $btnRestart.IsEnabled = $True
}
$btnRestart.Add_Click({rs})
$SqlService.ItemsSource = $observableCollection

[System.Windows.RoutedEventHandler]$EventsOnGrid = {
    $button = $_.OriginalSource.Name
    if ($button -eq "Restart") {
        $ArcsStyle.IsActive = $True
        [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMetroDialogAsync($Form, $Dialog, $settings)
    }
}
$SqlService.AddHandler([System.Windows.Controls.Button]::ClickEvent, $EventsOnGrid)
$Form.ShowDialog() | Out-Null