
## Check PreQA ESXi host 167
echo `n | Out-File C:\ip_failed.txt -Append
echo `n | Out-File C:\ip_failed.txt -Append
echo `n | Out-File C:\ip_failed.txt -Append
echo "**********************************************************************************" | Out-File C:\ip_failed.txt -Append
echo `t`t"ESXi HOST 167" | Out-File C:\ip_failed.txt -Append
## Test ping 

TestPing 10.9.0.167

## Test vSphere Client port

TestPort-Host -IPAddress 10.9.0.167 -Port 443 -Protocol TCP

## Test SSH to host

TestPort-Host -IPAddress 10.9.0.167 -Port 22 -Protocol TCP

## Check PowerState/RDP to VMs in host 
Connect-VIServer -Server 10.9.0.167 -Protocol https -User root -Password abc#1234

$VMs_off = Get-VM | where {$_.PowerState -eq "PoweredOff"} | Select Name, PowerState
echo `n | Out-File C:\ip_failed.txt -Append
echo `n | Out-File C:\ip_failed.txt -Append
echo "################################" | Out-File C:\ip_failed.txt -Append
echo "Host 10.9.0.167 - Powered Off VMs: " | Out-File C:\ip_failed.txt -Append
echo $VMs_off.Name | Out-File C:\ip_failed.txt -Append
echo "################################" | Out-File C:\ip_failed.txt -Append

Get-VM | Select Name, PowerState, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolstatus";E={@($_.ExtensionData.Guest.ToolsVersionStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}} | Export-Csv 167_vm_ip.csv -NoTypeInformation

Import-Csv 167_vm_ip.csv |  

foreach {  
    $VMs = $_.ip
    $Names = $_.Name

    If($_.PowerState -eq "PoweredOff")
        {
        Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] VM $Names is powered off" -Credential $mycreds -BodyAsHtml "VM $Names is powered off"
        }
    If ($VMs) 
    {
        If ($_.PowerState -eq "PoweredOn")
        {
        #Test RDP for each VM
        TestPort-VM -IPAddress $VMs -Port 3389 -Protocol TCP 
        }
    }
    Else {Write-Host "Host 10.9.0.167 - Cannot get IP of $Names"; echo "Host 10.9.0.167 - Cannot get IP of $Names" | Out-File C:\ip_failed.txt -Append} 
}  




## Check PreQA ESXi host 168
echo `n | Out-File C:\ip_failed.txt -Append
echo `n | Out-File C:\ip_failed.txt -Append
echo `n | Out-File C:\ip_failed.txt -Append
echo "**********************************************************************************" | Out-File C:\ip_failed.txt -Append
echo `t`t"ESXi HOST 168" | Out-File C:\ip_failed.txt -Append

## Test ping 

TestPing 10.9.0.168

## Test vSphere Client port

TestPort-Host -IPAddress 10.9.0.168 -Port 443 -Protocol TCP

## Test SSH to hosts

TestPort-Host -IPAddress 10.9.0.168 -Port 22 -Protocol TCP

## Check PowerState/RDP to VMs in host 
Connect-VIServer -Server 10.9.0.168 -Protocol https -User root -Password abc#1234

$VMs_off = Get-VM | where {$_.PowerState -eq "PoweredOff"} | Select Name, PowerState
echo `n | Out-File C:\ip_failed.txt -Append
echo `n | Out-File C:\ip_failed.txt -Append
echo "################################" | Out-File C:\ip_failed.txt -Append
echo "Host 10.9.0.168 - Powered Off VMs: " | Out-File C:\ip_failed.txt -Append
echo $VMs_off.Name | Out-File C:\ip_failed.txt -Append
echo "################################" | Out-File C:\ip_failed.txt -Append

Get-VM | Select Name, PowerState, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolstatus";E={@($_.ExtensionData.Guest.ToolsVersionStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}} | Export-Csv 168_vm_ip.csv -NoTypeInformation

Import-Csv 168_vm_ip.csv |  

foreach {  
    $VMs = $_.ip
    $Names = $_.Name

    If($_.PowerState -eq "PoweredOff")
        {
        Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] VM $Names is powered off" -Credential $mycreds -BodyAsHtml "VM $Names is powered off"
        }
    If ($VMs) 
    {
        If ($_.PowerState -eq "PoweredOn")
        {
        #Test RDP for each VM
        TestPort-VM -IPAddress $VMs -Port 3389 -Protocol TCP 
        }
    }
    Else {Write-Host "Host 10.9.0.168 - Cannot get IP of $Names"; echo "Host 10.9.0.168 - Cannot get IP of $Names" | Out-File C:\ip_failed.txt -Append} 
}  



## Check PreQA ESXi host 169
echo `n | Out-File C:\ip_failed.txt -Append
echo `n | Out-File C:\ip_failed.txt -Append
echo `n | Out-File C:\ip_failed.txt -Append
echo "**********************************************************************************" | Out-File C:\ip_failed.txt -Append
echo `t`t"ESXi HOST 169" | Out-File C:\ip_failed.txt -Append

## Test ping 

TestPing 10.9.0.169

## Test vSphere Client port

TestPort-Host -IPAddress 10.9.0.169 -Port 443 -Protocol TCP

## Test SSH to hosts

TestPort-Host -IPAddress 10.9.0.169 -Port 22 -Protocol TCP

## Check PowerState/RDP to VMs in host 
Connect-VIServer -Server 10.9.0.169 -Protocol https -User root -Password abc#1234

$VMs_off = Get-VM | where {$_.PowerState -eq "PoweredOff"} | Select Name, PowerState
echo `n | Out-File C:\ip_failed.txt -Append
echo `n | Out-File C:\ip_failed.txt -Append
echo "################################" | Out-File C:\ip_failed.txt -Append
echo "Host 10.9.0.169 - Powered Off VMs: " | Out-File C:\ip_failed.txt -Append
echo $VMs_off.Name | Out-File C:\ip_failed.txt -Append
echo "################################" | Out-File C:\ip_failed.txt -Append

Get-VM | Select Name, PowerState, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolstatus";E={@($_.ExtensionData.Guest.ToolsVersionStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}} | Export-Csv 169_vm_ip.csv -NoTypeInformation

Import-Csv 169_vm_ip.csv |  

foreach {  
    $VMs = $_.ip
    $Names = $_.Name
    If ($VMs) 
    {
    #Test RDP for each VM
    TestPort-VM -IPAddress $VMs -Port 3389 -Protocol TCP
    }
    Else {Write-Host "Host 10.9.0.169 - Cannot get IP of $Names"; echo "Host 10.9.0.169 - Cannot get IP of $Names" | Out-File C:\ip_failed.txt -Append} 
}  