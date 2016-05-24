


## Variable declaration
    #Email
$secpasswd = ConvertTo-SecureString "password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("user1@behappy.local", $secpasswd)
    #Test
$ping_failed = $false
$connect_failed = $false
$VMs_failed = $false

## Function declaration

Function ConvertToHtml
{
Param(
        [parameter(ParameterSetName='SourceFile', Position=0)]
        [string]
        $SourceFile,

       [parameter(ParameterSetName='SourceFile', Position=1)]
        [string]
        $TargetFile

        )

$File = Get-Content $SourceFile
$FileLine = @()
Foreach ($Line in $File) {
 $MyObject = New-Object -TypeName PSObject
 Add-Member -InputObject $MyObject -Type NoteProperty -Name Report -Value $Line
 $FileLine += $MyObject
}
$FileLine | ConvertTo-Html -Property Report | Out-File $TargetFile

$content = Get-Content $TargetFile

} # End function ConvertToHtml


Function TestPing
{

Param($hosts_ip)

If (Test-Connection $hosts_ip -Quiet) 
    {
    Write-Host "Ping host $hosts_ip sucessfully";
    echo "Ping successfully to $hosts_ip" | Out-File C:\ip_success.txt -Append -Width 120
    }
Else
    {
    Write-Host "Cannot ping host $hosts_ip";
    echo "Cannot ping to $hosts_ip" | Out-File C:\ip_failed.txt -Append
    $ping_failed = $true
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
            $connect_failed = $true
            #Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] ESXi host $hosts_ip got problem" -Credential $mycreds -BodyAsHtml "Cannot connect to ESXi host $RemoteServer port $Port"
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
            $connect_failed = $true
            #Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] ESXi host $hosts_ip got problem" -Credential $mycreds -BodyAsHtml "Cannot connect to ESXi host $RemoteServer port $Port"
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
            $connect_failed = $true
            #Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] VM $Names - $hosts_ip got problem" -Credential $mycreds -BodyAsHtml "Cannot connect to VM $Names - $RemoteServer port $Port"
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
            $connect_failed = $true
            #Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] VM $Names - $hosts_ip got problem" -Credential $mycreds -BodyAsHtml "Cannot connect to VM $Names - $RemoteServer port $Port"
        }
        Finally
        {
            $test.Dispose();
        }
    }
} ## End function TestPort-VM


## Disconnect to all ESXi hosts

Disconnect-VIServer -Server * -Force -Confirm:$false

## Check ESXi host

$Hostlist = Get-Content C:\List_ESXi_host.txt
$Host_IP = @()

Foreach ($Host_IP in $Hostlist)
{

echo "**********************************************************************************" | Out-File C:\ip_failed.txt -Append
echo `t`t"ESXi HOST $Host_IP" | Out-File C:\ip_failed.txt -Append

## Test ping 

TestPing $Host_IP

## Test vSphere Client port

TestPort-Host -IPAddress $Host_IP -Port 443 -Protocol TCP

## Test SSH to host

TestPort-Host -IPAddress $Host_IP -Port 22 -Protocol TCP

## Connect to ESXi host

Connect-VIServer -Server $Host_IP -Protocol https -User root -Password P@ssw0rd

## Check for VM powerstate change

$VMs_on_before = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState | Out-File VMbefore.txt

Sleep 120

$VMs_on_after = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState | Out-File VMafter.txt
If ((Get-Content VMafter.txt) -eq $null)
{ 

$VMs_off = Get-VM | where {$_.PowerState -eq "PoweredOff"} | Select Name, PowerState

}
Else
{
$result = Compare-Object (Get-Content VMbefore.txt) (Get-Content VMafter.txt)
$VMs_off = $result.InputObject -split "\s+" | select-string -pattern "PoweredOn" -notmatch | where {$_ -ne ""}
}

If ($result -ne $null) { $VMs_failed = $true } 

echo `n | Out-File C:\ip_failed.txt -Append
echo "################################" | Out-File C:\ip_failed.txt -Append
echo "Host $Host_IP - Powered Off VMs: " | Out-File C:\ip_failed.txt -Append
echo $VMs_off.Name | Out-File C:\ip_failed.txt -Append
echo "################################" | Out-File C:\ip_failed.txt -Append

## check RDP to each powered on VM
Get-VM | Select Name, PowerState, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolstatus";E={@($_.ExtensionData.Guest.ToolsVersionStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}} | Export-Csv 185_vm_ip.csv -NoTypeInformation

Import-Csv 185_vm_ip.csv |  
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
    Else {Write-Host "Host 10.9.0.185 - Cannot get IP of $Names"; echo "Host 10.9.0.185 - Cannot get IP of $Names" | Out-File C:\ip_failed.txt -Append} 
}  

} # End loop

## Add timestamp

$filename_failed = "ip_failed_" + (Get-Date -UFormat "%d_%m_%Y_%H_%M_%S") +".log"
$filename_success = "ip_success_" + (Get-Date -UFormat "%d_%m_%Y_%H_%M_%S") +".log"
Rename-Item -path C:\ip_failed.txt -NewName $filename_failed
Rename-Item -path C:\ip_success.txt -NewName $filename_success



### Send report email

ConvertToHtml -SourceFile $filename_failed -TargetFile C:\ip_failed.htm

If (($ping_failed = $true) -or ($connect_failed = $true) -or ($VMs_failed = $true))
{ 

Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] Alarm from Monitor Script" -Credential $mycreds -BodyAsHtml "$content"
}
Else {}
## Delete temp files and move to log folder

Move-Item $filename_failed C:\scriptlog
Move-Item $filename_success C:\scriptlog

Remove-Item C:\185_vm_ip.csv, C:\169_vm_ip.csv, C:\168_vm_ip.csv, C:\167_vm_ip.csv, C:\ip_failed.htm
