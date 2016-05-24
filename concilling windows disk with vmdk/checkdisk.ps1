#Example snippet to tie a Windows Volume to a VMware 

#Define computername
    $computer = "SYDSP001"

#Change this as needed.  Our standard display name is the hostname followed by a space...
    $VMView = Get-View -ViewType VirtualMachine -Filter @{'Name' = "$computer "}

#Thanks go to Richard Siddaway for the basic queries to tie diskdrive>partition>logicaldisk.
#http://itknowledgeexchange.techtarget.com/powershell/mapping-physical-drives-to-logical-drives-part-3/
    $ServerDiskToVolume = @(
        Get-WmiObject -Class Win32_DiskDrive -ComputerName $computer | foreach {
        
            $Dsk = $_
            $query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($_.DeviceID)'} WHERE ResultClass=Win32_DiskPartition" 
        
            Get-WmiObject -Query $query -ComputerName $computer | foreach { 
            
                $query = "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($_.DeviceID)'} WHERE ResultClass=Win32_LogicalDisk" 
            
                Get-WmiObject -Query $query -ComputerName $computer | Select DeviceID,
                    VolumeName,
                    @{ label = "SCSITarget"; expression = {$dsk.SCSITargetId} },
                    @{ label = "SCSIBus"; expression = {$dsk.SCSIBus} }
            }
        }
    )


# Now loop thru all the SCSI controllers on the VM and find those that match the Controller and Target
    $VMDisks = ForEach ($VirtualSCSIController in ($VMView.Config.Hardware.Device | Where {$_.DeviceInfo.Label -match "SCSI Controller"}))
    {
        ForEach ($VirtualDiskDevice  in ($VMView.Config.Hardware.Device | Where {$_.ControllerKey -eq $VirtualSCSIController.Key}))
        {

            #Build a custom object to hold this.  We use PS3 language...
            [pscustomobject]@{
                VM = $VM.Name
                HostName = $VMView.Guest.HostName
                PowerState = $VM.PowerState
                DiskFile = $VirtualDiskDevice.Backing.FileName
                DiskName = $VirtualDiskDevice.DeviceInfo.Label
                DiskSize = $VirtualDiskDevice.CapacityInKB * 1KB
                SCSIController = $VirtualSCSIController.BusNumber
                SCSITarget = $VirtualDiskDevice.UnitNumber
                DeviceID = $null
            }
        
            #Match up this VM to a logical disk
                $MatchingDisk = @( $ServerDiskToVolume | Where {$_.SCSITarget -like $VMSummary.SCSITarget -and $_.SCSIBus -like $VMSummary.SCSIController} )
            
            #Shouldn't happen, but just in case..
                if($MatchingDisk.count -gt 1)
                {
                    Write-Error "too many matches: $($MatchingDisk | select -property deviceid, partitions, SCSI* | out-string)"
                    $VMSummary.DeviceID = "Error: Too Many"
                }
                elseif($MatchingDisk.count -eq 1)
                {
                    $VMSummary.DeviceID = $MatchingDisk.DeviceID
                }
                else
                {
                    Write-Error "no match found"
                    $VMSummary.DeviceID = "Error: None found"
                }

            $VMSummary
        }
    }