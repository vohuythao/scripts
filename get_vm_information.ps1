#Remove user and pass if you wish to pass-through auth
Connect-VIServer <SERVERNAME> -user <username> -password <password>
$allvminfo = @()
$vms = Get-Vm

foreach($vm in $vms){
$vminfo = "" | Select Name, Host, PowerState, CPUCount, RAMAssigned, ProvisionedSpace, UsedSpace, UnusedSpace
$VMHost = Get-VM $vm.Name | select Host 
$VMHost = $VMHost.Host 
$VMPowerState = Get-VM $vm.Name | select PowerState 
$VMPowerState = $VmPowerState.PowerState 
$CPUCount = Get-VM $vm.Name | select NumCpu 
$CPUCount = $CPUCount.NumCpu 
$RAMAssigned = Get-VM $vm.Name | select MemoryGB 
$RAMAssigned = $RAMAssigned.MemoryGB 
$vmview = Get-VM $vm.Name | Get-View
$ProvisionedSpace = Get-VM $vm.Name | select ProvisionedSpaceGB
$ProvisionedSpace = $ProvisionedSpace.ProvisionedSpaceGB
$ProvisionedSpace = [math]::round($ProvisionedSpace, 2)
$vmview.Storage.PerDatastoreUsage.Committed.gettype() 
$UsedSpace = [math]::round(($vmview.Storage.PerDatastoreUsage.Committed/1024/1024/1024), 2) 
$UsedSpace =$UsedSpace.ToString() 
$UsedSpace = $UsedSpace + " GB" 
$UnUsedSpace = [math]::round(($vmview.Storage.PerDatastoreUsage.UnCommitted/1024/1024/1024), 2)
$UnUsedSpace =$UnUsedSpace.ToString() 
$UnUsedSpace = $UnUsedSpace + " GB" 
$ProvisionedSpace =$ProvisionedSpace.ToString() 
$ProvisionedSpace = $ProvisionedSpace + " GB" 

	$vminfo.Name = $vm.Name
	$vminfo.Host = $VMHost
	$vminfo.PowerState = $VMPowerState
	$vminfo.CPUCount = $CPUCount
	$vminfo.RAMAssigned = $RAMAssigned
	$vminfo.ProvisionedSpace = $ProvisionedSpace
	$vminfo.UsedSpace = $UsedSpace
	$vminfo.UnUsedSpace = $UnUsedSpace
	$allvminfo += $vminfo
}
$allvminfo | Select Name, Host, PowerState, CPUCount, RAMAssigned, ProvisionedSpace, UsedSpace, UnusedSpace | Export-Csv "E:\VMs.csv" -noTypeInformation