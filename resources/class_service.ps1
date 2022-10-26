class WinService {
    [String]$Status
    [String]$ServiceName

    WinService () {}

    WinService ([String]$ServiceName, [String]$Status) {
        $this.ServiceName = $ServiceName
        $this.Status = $Status
    }

    static [System.Collections.ObjectModel.ObservableCollection[Object]]GetServices ($SearchString) {
        $Services = Get-Service "*$SearchString*"
        $out = [System.Collections.ObjectModel.ObservableCollection[Object]]::new()
        $Services | ForEach-Object {
            $o = [WinService]::new($_.Name, $_.Status)
            $out.Add($o) | Out-Null
        }
        return $out
    }
}