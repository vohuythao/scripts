 #Working directory

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

cd $scriptPath

#Functions
Function logger ($message) {Write-Host -ForegroundColor Green (Get-Date -format "yyyyMMdd-HH.mm.ss") `n "$message" `n}
Function loggeralert ($message) {Write-Host -ForegroundColor Red (Get-Date -format "yyyyMMdd-HH.mm.ss") `n "$message" `n}
Function PowerOff-VM($vm){
   Shutdown-VMGuest -VM $vm -Confirm:$false | Out-Null
   Logger "$vm is stopping!"
   sleep 5
   $shutdown = "starting"
   $time = 1
   # Now check if the VM is shutdown in 60 loops with each 5 seconds of waittime, and if not perform a hard shutdown
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
   return $shutdown
}

#Running

If (Test-Path .\information.csv)
{

    Import-Csv .\information.csv |  
    foreach {  
        $Host_IP = $_.host_ip
        $user = $_.username
        $pass = $_.password | Out-File .\temppassword_$Host_IP.txt
        
        #Get credential to connect

        $filepass = ".\temppassword_$Host_IP.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $user, (Get-Content $filepass | ConvertTo-SecureString)

        #Connect to ESXi host

        Connect-VIServer -Server $Host_IP -Protocol https -Credential $cred -ErrorAction SilentlyContinue

        If ($global:DefaultVIServer -eq $null) 
        {
            Write-Host "Cannot Connect-VIServer to $Host_IP"
            echo "Cannot make a connection use Connect-VIServer to $Host_IP"
        }
        Else    
        {
            Write-Host "Connect-VIServer to $Host_IP successfully"

            #Check if all VMs are powered off

            $VMs_on = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState
            If ($VMs_on -eq $null)
            {
                Write-Host "All VMs are powered off "
                echo "All VMs are powered off " 
            }
            Else 
            {
                #Turn off all VMs
               PowerOff-VM $VMs_on.Name   
            }  
        }

        #Shutdown ESXi host

        sleep 300

        (Get-VMHost).ExtensionData.ShutdownHost_Task($TRUE)
            
        #Disconnect ESXi host

        Disconnect-VIServer -Server $Host_IP -Force -Confirm:$false
        Remove-Item .\temppassword_$Host_IP.txt

    } #End for each host loop

} #End if exist Information.csv

Else 
{
Write-Host "Cannot find information.csv, please check again!!!"
}