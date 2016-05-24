function find-thin{
    write-host -fore green `n "getting all VMs, this may take a while"
 
    $vms = get-vm |sort name | get-view
 
    Write-host -fore green `n "Starting Scan"
 
    $vmdks = @()
 
    foreach ($vm in $vms){
        foreach ($device in $vm.config.hardware.Device){
            if($device.GetType().Name -eq "VirtualDisk"){
                if($device.Backing.ThinProvisioned){
                    $info = "" | Select VM, File, SizeInGB, Thin
                    $info.VM = $vm.name
                    $info.File = $device.backing.filename
                    $info.SizeInGB = $device.capacityinkb/1048576
                    $info.thin = $device.Backing.ThinProvisioned
                    $vmdks += $info
                }
            }
        }
    }
 
    write-host -fore green `n "finished searching all VMs" `n
 
    $vmdks | export-csv c:\thindisk.csv -NoTypeInformation
}
 
find-thin