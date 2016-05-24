
## Email information

$secpasswd = ConvertTo-SecureString "password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("user1@behappy.local", $secpasswd)

## Function declaration

Function TestPort
{
    Param(
        #[parameter(ParameterSetName='ComputerName', Position=0)]
        #[string]
        #$ComputerName,

        [parameter(ParameterSetName='IP', Position=0)]
        [System.Net.IPAddress]
        $IPAddress,

        [parameter(Mandatory=$true , Position=1)]
        [int]
        $Port,

        [parameter(Mandatory=$true, Position=2)]
        [ValidateSet("TCP", "UDP")]
        [string]
        $Protocol
        )

    $RemoteServer = If ([string]::IsNullOrEmpty($ComputerName)) {$IPAddress} Else {$ComputerName};

    If ($Protocol -eq 'TCP')
    {
        $test = New-Object System.Net.Sockets.TcpClient;
        Try
        {
            Write-Host "Connecting to "$RemoteServer":"$Port" (TCP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Host "Connection successful";
            echo "Connect successfully to $RemoteServer port $Port" | ConvertTo-Html | Out-File C:\ip_success.htm -Append -Width 120
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $RemoteServer port $Port" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append -Width 120
        }
        Finally
        {
            $test.Dispose();
        }
    }

   If ($Protocol -eq 'UDP')
    {
        $test = New-Object System.Net.Sockets.UdpClient;
        Try
        {
            Write-Host "Connecting to "$RemoteServer":"$Port" (UDP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Host "Connection successful";
            echo "Connect successfully to $RemoteServer port $Port" | ConvertTo-Html | Out-File C:\ip_success.htm -Append -Width 120
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $RemoteServer port $Port" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append -Width 120
        }
        Finally
        {
            $test.Dispose();
        }
    }
}

Function TestSSH
{

     Param($hosts_ip)
$checkping = Test-Connection $hosts_ip -Quiet

If ($checkping) 
    {

    TestPort -IPAddress $hosts_ip -Port 22 -Protocol TCP
    }
Else
    {
    Write-Host "Cannot ping host $hosts_ip";
    echo "Cannot ping to $hosts_ip" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
    Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] ESXi host $hosts_ip got problem" -Credential $mycreds -BodyAsHtml "PLEASE CHECK HOST $hosts_ip"
    }


} # End function TestSSH

Function TestvSphereClient
{

     Param($hosts_ip)
$checkping = Test-Connection $hosts_ip -Quiet

If ($checkping) 
    {

    TestPort -IPAddress $hosts_ip -Port 443 -Protocol TCP
    }
Else
    {
    Write-Host "Cannot ping host $hosts_ip";
    echo "Cannot ping to $hosts_ip" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
    }


} # End function TestvSphereClient

Function TestRDP
{

     Param($VMs_ip)
$checkping = Test-Connection $VMs_ip -Quiet

If ($checkping) 
    {

    TestPort -IPAddress $VMs_ip -Port 3389 -Protocol TCP
    }
Else
    {
    Write-Host "Cannot ping VM $VMs_ip";
    #echo "Cannot ping to $VMs_ip" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
    TestPort -IPAddress $VMs_ip -Port 3389 -Protocol TCP
    }

} # End function TestRDP


## Disconnect to all ESXi hosts

Disconnect-VIServer -Server * -Force -Confirm:$false

## Check test ESXi host 185
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "**********************************************************************************" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `t`t"ESXi HOST 185" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
##Test vSphere Client port
TestvSphereClient 10.9.1.185
## Test SSH to hosts
TestSSH 10.9.1.185
## Check PowerState/RDP to VMs in host 
Connect-VIServer -Server 10.9.1.185 -Protocol https -User root -Password P@ssw0rd

$VMs_off = Get-VM | where {$_.PowerState -eq "PoweredOff"} | Select Name, PowerState
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "################################" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "Host 10.9.1.185 - Powered Off VMs: " | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo $VMs_off.Name | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "################################" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append

Get-VM | Select Name, @{N="ip";E={@($_.guest.IPAddress[0])}} | Export-Csv 185_vm_ip.csv -NoTypeInformation

Import-Csv 185_vm_ip.csv |  

foreach {  
    $VMs = $_.ip
    $Names = $_.Name
    If ($VMs) 

    {
    #Test RDP for each VM
    TestRDP $VMs 
    }
    Else {Write-Host "Host 10.9.1.185 - Cannot get IP of $Names"; echo "Host 10.9.1.185 - Cannot get IP of $Names" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append} 
}  


## Check PreQA ESXi host 167
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "**********************************************************************************" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `t`t"ESXi HOST 167" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
##Test vSphere Client port
TestvSphereClient 10.9.0.167
## Test SSH to hosts
TestSSH 10.9.0.167
## Check PowerState/RDP to VMs in host 
Connect-VIServer -Server 10.9.0.167 -Protocol https -User root -Password abc#1234

$VMs_off = Get-VM | where {$_.PowerState -eq "PoweredOff"} | Select Name, PowerState
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "################################" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "Host 10.9.0.167 - Powered Off VMs: " | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo $VMs_off.Name | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "################################" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append

Get-VM | Select Name, @{N="ip";E={@($_.guest.IPAddress[0])}} | Export-Csv 167_vm_ip.csv -NoTypeInformation

Import-Csv 167_vm_ip.csv |  

foreach {  
    $VMs = $_.ip
    $Names = $_.Name
    If ($VMs) 

    {
    #Test RDP for each VM
    TestRDP $VMs 
    }
    Else {Write-Host "Host 10.9.0.167 - Cannot get IP of $Names"; echo "Host 10.9.0.167 - Cannot get IP of $Names" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append} 
}  




## Check PreQA ESXi host 168
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "**********************************************************************************" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `t`t"ESXi HOST 168" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
##Test vSphere Client port
TestvSphereClient 10.9.0.168
## Test SSH to hosts
TestSSH 10.9.0.168
## Check PowerState/RDP to VMs in host 
Connect-VIServer -Server 10.9.0.168 -Protocol https -User root -Password abc#1234

$VMs_off = Get-VM | where {$_.PowerState -eq "PoweredOff"} | Select Name, PowerState
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "################################" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "Host 10.9.0.168 - Powered Off VMs: " | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo $VMs_off.Name | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "################################" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append

Get-VM | Select Name, @{N="ip";E={@($_.guest.IPAddress[0])}} | Export-Csv 168_vm_ip.csv -NoTypeInformation

Import-Csv 168_vm_ip.csv |  

foreach {  
    $VMs = $_.ip
    $Names = $_.Name
    If ($VMs) 

    {
    #Test RDP for each VM
    TestRDP $VMs 
    }
    Else {Write-Host "Host 10.9.0.168 - Cannot get IP of $Names"; echo "Host 10.9.0.168 - Cannot get IP of $Names" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append} 
}  


## Check PreQA ESXi host 169
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "**********************************************************************************" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `t`t"ESXi HOST 169" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
##Test vSphere Client port
TestvSphereClient 10.9.0.169
## Test SSH to hosts
TestSSH 10.9.0.169
## Check PowerState/RDP to VMs in host 
Connect-VIServer -Server 10.9.0.169 -Protocol https -User root -Password abc#1234

$VMs_off = Get-VM | where {$_.PowerState -eq "PoweredOff"} | Select Name, PowerState
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo `n | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "################################" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "Host 10.9.0.169 - Powered Off VMs: " | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo $VMs_off.Name | ConvertTo-Html | Out-File C:\ip_failed.htm -Append
echo "################################" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append

Get-VM | Select Name, @{N="ip";E={@($_.guest.IPAddress[0])}} | Export-Csv 169_vm_ip.csv -NoTypeInformation

Import-Csv 169_vm_ip.csv |  

foreach {  
    $VMs = $_.ip
    $Names = $_.Name
    If ($VMs) 

    {
    #Test RDP for each VM
    TestRDP $VMs 
    }
    Else {Write-Host "Host 10.9.0.169 - Cannot get IP of $Names"; echo "Host 10.9.0.169 - Cannot get IP of $Names" | ConvertTo-Html | Out-File C:\ip_failed.htm -Append} 
}  

## Add timestamp

$filename_failed = "ip_failed_" + (Get-Date -UFormat "%d_%m_%Y_%H_%M_%S") +".log"
$filename_success = "ip_success_" + (Get-Date -UFormat "%d_%m_%Y_%H_%M_%S") +".log"
Rename-Item -path C:\ip_failed.htm -NewName $filename_failed
Rename-Item -path C:\ip_success.htm -NewName $filename_success

### Send report email

$content = Get-Content $filename_failed
Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "Report from Monitor Script" -Credential $mycreds -BodyAsHtml "$content"

## Delete temp files and move to log folder

Move-Item $filename_failed .\scriptlog
Move-Item $filename_success .\scriptlog

Remove-Item C:\185_vm_ip.csv, C:\169_vm_ip.csv, C:\168_vm_ip.csv, C:\167_vm_ip.csv
