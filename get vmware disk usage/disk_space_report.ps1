ForEach ($VM in Get-VM | where-object {($_.powerstate -ne "PoweredOff") -and ($_.Extensiondata.Guest.ToolsStatus -Match ".*Ok.*")}){
 
ForEach ($Drive in $VM.Extensiondata.Guest.Disk) {
 
$Path = $Drive.DiskPath
 
#Calculations 
$Freespace = [math]::Round($Drive.FreeSpace / 1MB)
$Capacity = [math]::Round($Drive.Capacity/ 1MB)
 
$SpaceOverview = "$Freespace" + "/" + "$capacity" 
$PercentFree = [math]::Round(($FreeSpace)/ ($Capacity) * 100) 
 
#VMs with less space
if ($PercentFree -lt 20) {     
    $Output = $Output + "VM: " + $VM.Name + "`n"
    $Output = $Output + "Disk: " + $Path + "`n"
    $OutPut = $Output + "Free(MB): " + $Freespace + "`n"
    $Output = $Output + "Free(%): " + $PercentFree + "`n"  
}
 
} # End ForEach ($Drive in in $VM.Extensiondata.Guest.Disk)
 
} # End ForEach ($VM in Get-VM)
 
$Output