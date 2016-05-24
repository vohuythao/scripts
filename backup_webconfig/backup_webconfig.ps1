 # Start Loading SharePoint Snap-in
    $snapin = Get-PSSnapin | Where-Object { $_.Name -eq 'Microsoft.SharePoint.PowerShell'}
    if($snapin -eq $null) {
        Add-PSSnapin "Microsoft.SharePoint.PowerShell"
    }
    # End Loading SharePoint Snapin

# Backup web.config
$datetime = (Get-Date -f dd_MM_yyyy)
$webapp = Get-SPWebApplication
foreach ($web in $webapp) {
$webname = $web.DisplayName
Write-Host "Backing up $webname web.config file…" -foreground Gray –nonewline

## Get the web application – by display name 
$w = Get-SPWebApplication | where { $_.DisplayName -eq "$webname"}

## Get the default (first) zone for the web app… 
## You may wish to iterate through all the available zones 
$zone = $w.AlternateUrls[0].UrlZone

## Get the collection of IIS settings for the zone 
$iisSettings = $w.IisSettings[$zone]

## Get the path from the settings 
$path = $iisSettings.Path.ToString() + "\web.config"

## copy the web.config file from the path 
$backupDir = $iisSettings.Path.ToString() + "\_Backup"
copy-item $path -destination $backupDir
Get-ChildItem $backupDir\web.config | Rename-Item -NewName {$_.BaseName+"_"+($datetime)+$_.Extension}
Write-Host "done" -foreground Green

## Delete old files
        $list = Get-ChildItem $backupDir\*.config | Select Name

        foreach ($file in $list)
        {
            $compare_time = ((Get-Date) - (Get-ChildItem $backupDir\$file).LastAccessTime).TotalDays
            If ($compare_time -gt 30)
            {
                Remove-Item $backupDir\$file
                Write-Host "Remove $file follow the retention policy" -ForegroundColor Cyan
            }
        }

}
