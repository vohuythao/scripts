###########################################################################################
# Title:	ESXi and VMs monitor script 
# Filename:	monitorscript.sp1       	
# Created by:	Thao Vo t.vo@aswigsolutions.com			
# Date:		18-05-2015					
# Version       1.1					
###########################################################################################
# Description:	Scripts that monitor the status of a VMware      
# enviroment on the following point:		
# - Check ping to ESXi hosts	       	
# - Check SSH/vSphere client to ESXi hosts				
# - Monitor the power state of each VMs in every ESXi hosts			
# - Send immediately alert email if host is down
# - If get any failure, send cumulative alert email after x minutes		
###########################################################################################
# Configuration:
#   1.Browse to the working directory where the monitorscript.ps1 script resides
#   2.Open powershell, type :
#        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
#        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
#        Set-PowerCLIConfiguration -ProxyPolicy NoProxy -Confirm:$false
#   3.Make the password more security : open powershell, type :
#        "your ESXi host password" | ConvertTo-SecureString -AsPlainText -Force |
#        ConvertFrom-SecureString | Out-File "<working directory>\Password.txt"
#   
#   4.Create a txt file, name "List_ESXi_host.txt", each line is IP address of each ESXi host
#   5.Create a folder name "scriptlog" for contain the log file
#   6.Edit the monitorscript.ps1 file and fill in the blank variables in Variable declaration
#  
###########################################################################################
# Usage:
#   Manually run the monitorscipt.ps1 script": 
#   1.Browse to the directory where the monitorscript.ps1 script resides
#   2.Open powershell
#   5.Enter the command:
#   .\monitorscript.ps1
#
#   To create a schedule task use the following 
#   syntax in the run property:
#   powershell -file "path\monitorscript.ps1"
#   edit the path 
###########################################################################################

##########################
# Move to working folder #
##########################

 #Working directory, that must contain "monitorscript.ps1", "List_ESXi_host.txt", and folder "scriptlog"

$path = "C:\"

cd $path 

#########################
# Variable declaration  #
#########################
   
    #Email

$smtp_server = "10.9.0.22"
$recipients = "t.vo@aswigsolutions.com"
[string[]]$cc_recipients = "Vinh Nguyen <v.nguyen@aswigsolutions.com>", "Trang Tran <t.minh@aswigsolutions.com>"
$username = "user1@behappy.local"
$password = "password"
$secpasswd = ConvertTo-SecureString "$password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("$username", $secpasswd)

    #ESXi username and password

$vcuser = "root"
$File = ".\Password.txt"
$cred = New-Object -TypeName System.Management.Automation.PSCredential `
 -ArgumentList $vcuser, (Get-Content $File | ConvertTo-SecureString)

    #Test variable

$global:ping_failed = $false
$global:connect_failed = $false
$global:VMs_failed = $false
$global:VMstools_failed = $false


#########################
# Function declaration  #
#########################

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


} #End function ConvertToHtml


Function TestPing
{

Param($Host_IP)

If (Test-Connection $Host_IP -Quiet) 
    {
    Write-Host "Ping host $Host_IP sucessfully";
    echo "Ping successfully to $Host_IP" | Out-File .\ip_success.txt -Append -Width 120
    }
Else
    {
    Write-Host "Cannot ping host $Host_IP";
    echo "Cannot ping to $Host_IP" | Out-File .\ip_failed.txt -Append
    $global:ping_failed = $true
    Send-MailMessage -to $recipients -Cc $cc_recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] ESXi host $Host_IP got problem" -Credential $mycreds -BodyAsHtml "Cannot ping to ESXi host $Host_IP"
    }

} #End function TestPing

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
            echo "Connect successfully to ESXi host $RemoteServer port $Port" | Out-File .\ip_success.txt -Append -Width 120
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to ESXi host $RemoteServer port $Port" | Out-File .\ip_failed.txt -Append -Width 120 
            echo "Cannot connect to ESXi host $RemoteServer port $Port" | Out-File .\report.txt -Append 
            $global:connect_failed = $true
            #Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] ESXi host $RemoteServer got problem" -Credential $mycreds -BodyAsHtml "Cannot connect to ESXi host $RemoteServer port $Port"
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
            echo "Connect successfully to ESXi host $RemoteServer port $Port" | Out-File .\ip_success.txt -Append -Width 120
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to ESXi host $RemoteServer port $Port" | Out-File .\ip_failed.txt -Append -Width 120 
            echo "Cannot connect to ESXi host $RemoteServer port $Port" | Out-File .\report.txt -Append 
            $global:connect_failed = $true
            #Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] ESXi host $hosts_ip got problem" -Credential $mycreds -BodyAsHtml "Cannot connect to ESXi host $RemoteServer port $Port"
        }
        Finally
        {
            $test.Dispose();
        }
    }
} #End function TestPort-Host



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
            Write-Host "Connecting to $Names "$RemoteServer":"$Port" (TCP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Host "Connection successful";
            echo "Connect successfully to $Names - $RemoteServer port $Port" | Out-File .\ip_success.txt -Append -Width 120
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $Names - $RemoteServer port $Port" | Out-File .\ip_failed.txt -Append -Width 120 
            echo "Cannot connect to $Names - $RemoteServer port $Port" | Out-File .\report.txt -Append 
            $global:connect_failed = $true
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
            Write-Host "Connecting to $Names "$RemoteServer":"$Port" (UDP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Host "Connection successful";
            echo "Connect successfully to $Names - $RemoteServer port $Port" | Out-File .\ip_success.txt -Append -Width 120
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $Names - $RemoteServer port $Port" | Out-File .\ip_failed.txt -Append -Width 120 
            echo "Cannot connect to $Names - $RemoteServer port $Port" | Out-File .\report.txt -Append 
            $global:connect_failed = $true
            #Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] VM $Names - $hosts_ip got problem" -Credential $mycreds -BodyAsHtml "Cannot connect to VM $Names - $RemoteServer port $Port"
        }
        Finally
        {
            $test.Dispose();
        }
    }
} #End function TestPort-VM

Function PowerStateChange

{

Param($Host_IP)

$VMs_on = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState | Out-File .\VMnow_$Host_IP.txt
$VMs_off = Get-VM | where {$_.PowerState -eq "PoweredOff"}
$result = Compare-Object (Get-Content VMlasttime_$Host_IP.txt) (Get-Content VMnow_$Host_IP.txt)

If ($result -eq $null)
{
echo `n | Out-File ip_failed.txt -Append
echo "################################" | Out-File .\ip_failed.txt -Append
echo "There is no VMs has just changed powerstate" | Out-File .\ip_failed.txt -Append
echo "################################" | Out-File .\ip_failed.txt -Append
}
ElseIf ($VMs_off -eq $null)
    {$global:VMs_failed = $false}
Else
{
$VMs_just_change = $result.InputObject -split "\s+" | select-string -pattern "PoweredOn" -notmatch | where {$_ -ne ""}
$global:VMs_failed = $true

echo `n | Out-File ip_failed.txt -Append
echo "################################" | Out-File .\ip_failed.txt -Append
echo "Host $Host_IP - Just changed powerstate VMs: " | Out-File .\ip_failed.txt -Append
echo $VMs_just_change | Out-File .\ip_failed.txt -Append
echo "################################" | Out-File .\ip_failed.txt -Append
} 

Move-Item VMnow_$Host_IP.txt VMlasttime_$Host_IP.txt -Force

} #End function PowerStateChange


#########################
# Get ESXi host list    #
#########################

$Hostlist = Get-Content .\List_ESXi_host.txt
$Host_IP = @()

Foreach ($Host_IP in $Hostlist)
{

echo `n`n"**********************************************************************************" | Out-File .\ip_failed.txt -Append 
echo `n`n"**********************************************************************************" | Out-File .\report.txt -Append 
echo `t`t"ESXi HOST $Host_IP" | Out-File .\ip_failed.txt -Append
echo `t`t"ESXi HOST $Host_IP" | Out-File .\report.txt -Append 

#########################
# Run the test          #
#########################

    #Test ping 

TestPing $Host_IP

    #Test vSphere Client ( port 902,443 )

TestPort-Host -IPAddress $Host_IP -Port 902 -Protocol TCP
TestPort-Host -IPAddress $Host_IP -Port 443 -Protocol TCP

    #Test SSH to host ( port 22 )

TestPort-Host -IPAddress $Host_IP -Port 22 -Protocol TCP

    #Connect to ESXi host

Connect-VIServer -Server $Host_IP -Protocol https -Credential $cred

If ($global:DefaultVIServer -eq $null) 

    {
    Send-MailMessage -to $recipients -Cc $cc_recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] ESXi host $Host_IP got problem" -Credential $mycreds -BodyAsHtml "Cannot use Connect-VIServer to ESXi host $Host_IP"
    }

    #Check for VM power state change

PowerStateChange $Host_IP

    #Check RDP to each powered on VM

Get-VM | Select Name, PowerState, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolstatus";E={@($_.Guest.ExtensionData.ToolsRunningStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}} | Export-Csv vm_ip.csv -NoTypeInformation

Import-Csv vm_ip.csv |  
foreach {  
    $VMs = $_.ip
    $Names = $_.Name
    $Toolstatus = $_.toolstatus

    If ($_.PowerState -eq "PoweredOn")
    {
        If ($VMs) 
        {
        #Test RDP for each VM
        TestPort-VM -IPAddress $VMs -Port 3389 -Protocol TCP 
        }
        ElseIf ($_.toolstatus -ne "guestToolsRunning")

         {Write-Host "Host $Host_IP - VM $Names-$IPs VMware tools is not running"
         $VMstools_failed = $true
         echo "Host $Host_IP - $Names - $IPs VMware tools is not running" | Out-File .\ip_failed.txt -Append 
         echo "$Names - $IPs VMware tools is not running" | Out-File .\report.txt -Append }
    }
    Else {echo "$Names is powered off" | Out-File .\ip_failed.txt -Append | Out-File .\report.txt -Append
    echo "$Names is powered off" | Out-File .\report.txt -Append }
}  

Remove-Item vm_ip.csv

    #Disconnect ESXi host

Disconnect-VIServer -Server $Host_IP -Force -Confirm:$false

} #End loop


###########################
# Finalize the process    #
###########################

    #Add timestamp

$filename_failed = "ip_failed_" + (Get-Date -UFormat "%d_%m_%Y_%H_%M_%S") +".log"
$filename_success = "ip_success_" + (Get-Date -UFormat "%d_%m_%Y_%H_%M_%S") +".log"
Rename-Item -path .\ip_failed.txt -NewName $filename_failed
Rename-Item -path .\ip_success.txt -NewName $filename_success

    #Send report email

ConvertToHtml -SourceFile .\report.txt -TargetFile .\report.htm
$content = Get-Content report.htm

If (($ping_failed) -or ($connect_failed) -or ($VMs_failed))
{ 
Send-MailMessage -to $recipients -Cc $cc_recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] Warning from Monitor Script" -Credential $mycreds -BodyAsHtml "$content"
}
Else {}

    #Delete temp files and move to log folder

Move-Item $filename_failed .\scriptlog
Move-Item $filename_success .\scriptlog
Remove-Item .\report.txt
Remove-Item .\report.htm
