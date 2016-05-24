do {
      $vmview = Get-VM $vm | Get-View
      $getvm = Get-VM $vm
      $powerstate = $getvm.PowerState
      $toolsstatus = $vmview.Guest.ToolsStatus
      logger "$vm is stopping with powerstate $powerstate and toolsStatus $toolsstatus!"
      sleep 5
      $time++
      if($time -eq 60){
        loggeralert "$vm is taking more than 5 minutes to shutdown. Hard powering off the VM."
        Stop-VM -VM $vm -Confirm:$false | Out-Null
      }
   }until(($powerstate -match "PoweredOff") -or ($time -eq 120))
   if ($powerstate -match "PoweredOff"){
      logger "$vm is powered-off"
   }
   else{$shutdown = "ERROR"}
   Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolversionstatus";E={@($_.ExtensionData.Guest.ToolsVersionStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}}, @{N="toolstatus";E={@($_.guest.toolsstatus)}}