  $RootFolder = "C:\Support\"
Get-VMHost | Foreach {
   Write-Host "Backing up state for $($_.Name)"
   $Date = Get-Date -f yyyy-MM-dd
   $Folder = $RootFolder + $Date + "\$($_.Name)\"
   If (-not (Test-Path $Folder)) {
      MD $Folder | Out-Null
   }
   $_ | Get-VMHostFirmware -BackupConfiguration -DestinationPath $RootFolder
   # Next line is a workaround for -DestinationPath not working correctly
   # with folder names with a - in them.
   MV ($RootFolder + "*") $Folder -ErrorAction SilentlyContinue