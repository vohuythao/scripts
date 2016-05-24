
$time = 1

do {

Get-VM | Select Name, PowerState, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolstatus";E={@($_.ExtensionData.Guest.ToolsVersionStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}} | Export-Csv vm_ip.csv -NoTypeInformation

Import-Csv vm_ip.csv |  
foreach {  
    $VMs = $_.ip
    $Names = $_.Name
    If ($_.PowerState -eq "PoweredOn")
    {
         If ($VMs) 
        {
        $stats = Get-Stat -Entity $Names -MaxSamples 1 -Stat "cpu.usage.average","mem.usage.average"
        $cpu = $stats| where {$_.MetricID -eq "cpu.usage.average"}
        $mem = $stats| where {$_.MetricID -eq "mem.usage.average"}
        If (($cpu.Value -gt 99) -or ($mem.Value -gt 85)) { echo "VM $Names got overload : CPU "$cpu.Value"% and RAM "$mem.Value"%" }

        }
        Else {
        Write-Host "Host $Host_IP - Cannot get IP of $Names or VMware Tool in $Names is not running"; 
        echo "Host $Host_IP - Cannot get IP of $Names or VMware Tool in $Names is not running" | Out-File C:\ip_failed.txt -Append}
     }
    Else {echo "$Names is powered off" | Out-File .\ip_failed.txt -Append}
    
}  # end foreach loop

Remove-Item vm_ip.csv
$time++

} until ($time -eq 10 ) 
 
#end do loop