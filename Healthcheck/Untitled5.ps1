# Threshold definition

$threshold_cpu = @()
$threshold_mem = @()


#########################
# Get ESXi host list    #
#########################

$Hostlist = Get-Content .\List_ESXi_host.txt
$Host_IP = @()

Foreach ($Host_IP in $Hostlist)
{

echo "**********************************************************************************" | Out-File .\ip_failed.txt -Append
echo `t`t"ESXi HOST $Host_IP" | Out-File .\ip_failed.txt -Append

#########################
# Run the test          #
#########################

    #Connect to ESXi host

Connect-VIServer -Server $Host_IP -Protocol https -User $vcuser -Password $vcpassword

    #Check for VM power state change

$VMs_on_before = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState | Out-File .\VMbefore_$Host_IP.txt

$result1 = Compare-Object (Get-Content VMlasttime_$Host_IP.txt) (Get-Content VMbefore_$Host_IP.txt)

Sleep 60

$VMs_on_after = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState | Out-File .\VMafter_$Host_IP.txt

$result2 = Compare-Object (Get-Content VMbefore_$Host_IP.txt) (Get-Content VMafter_$Host_IP.txt)

Move-Item VMafter_$Host_IP.txt VMlasttime_$Host_IP.txt -Force

If (($result1 -eq $null) -and ($result2 -eq $null))
{
echo `n | Out-File ip_failed.txt -Append
echo "################################" | Out-File .\ip_failed.txt -Append
echo "There is no VMs has just turned off" | Out-File .\ip_failed.txt -Append
echo "################################" | Out-File .\ip_failed.txt -Append
}
Else
{
$VMs_just_off1 = $result1.InputObject -split "\s+" | select-string -pattern "PoweredOn" -notmatch | where {$_ -ne ""}
$VMs_just_off2 = $result2.InputObject -split "\s+" | select-string -pattern "PoweredOn" -notmatch | where {$_ -ne ""}
$VMs_failed = $true

echo `n | Out-File ip_failed.txt -Append
echo "################################" | Out-File .\ip_failed.txt -Append
echo "Host $Host_IP - Just Powered Off VMs: " | Out-File .\ip_failed.txt -Append
echo $VMs_just_off1 | Out-File .\ip_failed.txt -Append
echo $VMs_just_off2 | Out-File .\ip_failed.txt -Append
echo "################################" | Out-File .\ip_failed.txt -Append
} 

Remove-Item VMbefore_$Host_IP.txt

    #Check RDP to each powered on VM

Get-VM | Select Name, PowerState, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolstatus";E={@($_.ExtensionData.Guest.ToolsVersionStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}} | Export-Csv vm_ip.csv -NoTypeInformation

Import-Csv vm_ip.csv |  
foreach {  
    $VMs = $_.ip
    $Names = $_.Name

    If ($VMs) 
    {
        If ($_.PowerState -eq "PoweredOn")
        {
        #Test RDP for each VM
        TestPort-VM -IPAddress $VMs -Port 3389 -Protocol TCP 
        }
        Else {}
    }
    Else 
    {Write-Host "Host $Host_IP - Cannot get IP of $Names"; 
    #echo "Host $Host_IP - Cannot get IP of $Names" | Out-File C:\ip_failed.txt -Append
    }
}  

Remove-Item vm_ip.csv

} #End loop