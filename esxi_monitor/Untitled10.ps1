## Email information

$secpasswd = ConvertTo-SecureString "password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("user1@behappy.local", $secpasswd)

## Function declaration

Function TestPing
{

Param($hosts_ip)

$checkping = Test-Connection $hosts_ip -Quiet
If ($checkping) 
    {
    Write-Host "Ping host $hosts_ip sucessfully";
    echo "Ping successfully to $hosts_ip" | Out-File C:\ip_success.txt -Append -Width 120
    }
Else
    {
    Write-Host "Cannot ping host $hosts_ip";
    echo "Cannot ping to $hosts_ip" | Out-File C:\ip_failed.txt -Append
    Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] ESXi host $hosts_ip got problem" -Credential $mycreds -BodyAsHtml "Cannot ping to ESXi host $hosts_ip"
    }

} ## End function TestPing

Function TestPort-Host
{
    Param(
        [parameter(ParameterSetName='ComputerName', Position=0)]
        [string]
        $ComputerName,

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
            echo "Connect successfully to ESXi host $RemoteServer port $Port" | Out-File C:\ip_success.txt -Append -Width 120
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to ESXi host $RemoteServer port $Port" | Out-File C:\ip_failed.txt -Append -Width 120
            Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] ESXi host $hosts_ip got problem" -Credential $mycreds -BodyAsHtml "Cannot connect to ESXi host $RemoteServer port $Port"
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
            echo "Connect successfully to ESXi host $RemoteServer port $Port" | Out-File C:\ip_success.txt -Append -Width 120
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to ESXi host $RemoteServer port $Port" | Out-File C:\ip_failed.txt -Append -Width 120
            Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] ESXi host $hosts_ip got problem" -Credential $mycreds -BodyAsHtml "Cannot connect to ESXi host $RemoteServer port $Port"
        }
        Finally
        {
            $test.Dispose();
        }
    }
} ## End function TestPort-Host



Function TestPort-VM
{
    Param(
        [parameter(ParameterSetName='ComputerName', Position=0)]
        [string]
        $ComputerName,

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
            echo "Connect successfully to $Names - $RemoteServer port $Port" | Out-File C:\ip_success.txt -Append -Width 120
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $Names - $RemoteServer port $Port" | Out-File C:\ip_failed.txt -Append -Width 120  
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
            echo "Connect successfully to $Names - $RemoteServer port $Port" | Out-File C:\ip_success.txt -Append -Width 120
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $Names - $RemoteServer port $Port" | Out-File C:\ip_failed.txt -Append -Width 120
        }
        Finally
        {
            $test.Dispose();
        }
    }
} ## End function TestPort-VM



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