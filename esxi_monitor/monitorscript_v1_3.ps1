###########################################################################################
# Title:	ESXi and VMs monitor script 
# Filename:	monitorscript.sp1       	
# Created by:	Thao Vo t.vo@aswigsolutions.com			
# Date:		28-05-2015					
# Version       1.3		
# - Move test RDP to function CheckRDP
# - Reorganize the test process			
###########################################################################################
# Description:	Scripts that monitor the status of a VMware      
# enviroment on the following point:		
# - Check the Connect-VIServer command to connect to ESXi host	       					
# - Monitor the power state of each VMs in every ESXi hosts			
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
#   5.Edit the monitorscript.ps1 file and fill in the blank variables in Variable declaration
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

    #Working directory, that must contain "monitorscript.ps1", "List_ESXi_host.txt"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

cd $scriptPath

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

    #Test variable

$global:connect_failed = $false
$global:VMs_failed = $false


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
    Add-Member -InputObject $MyObject -Type NoteProperty -Name REPORT -Value $Line
    $FileLine += $MyObject
}
    $FileLine | ConvertTo-Html -Property REPORT | Out-File $TargetFile


} #End function ConvertToHtml


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
            echo "Connect successfully to $Names - $RemoteServer port $Port" }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $Names - $RemoteServer port $Port"  
            echo "Cannot connect to $Names - $RemoteServer port $Port" | Out-File .\report.txt -Append 
            $global:connect_failed = $true
            
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
            echo "Connect successfully to $Names - $RemoteServer port $Port" 
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $Names - $RemoteServer port $Port"  
            echo "Cannot connect to $Names - $RemoteServer port $Port" | Out-File .\report.txt -Append 
            $global:connect_failed = $true
            
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

    $result = Compare-Object (Get-Content VMlasttime_$Host_IP.txt) (Get-Content VMnow_$Host_IP.txt)

    If ($result -eq $null)
    {  
    $global:VMs_failed = $false
    }
    Else 
    {
    $global:VMs_failed = $true 
    }
   

    Move-Item VMnow_$Host_IP.txt VMlasttime_$Host_IP.txt -Force

} #End function PowerStateChange

Function CheckRDP
{
    Param($Host_IP)
    Get-VM | Select Name, PowerState, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolstatus";E={@($_.Guest.ExtensionData.ToolsRunningStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}} | Export-Csv vm_ip.csv -NoTypeInformation

            Import-Csv vm_ip.csv |  
            foreach {  
            $VMs = $_.ip
            $Names = $_.Name

            If ($_.PowerState -eq "PoweredOn")
            {
                If ($VMs) 
                {
                #Test RDP for each VM
                TestPort-VM -IPAddress $VMs -Port 3389 -Protocol TCP 
                }
        
            }
            Else {echo "$Names is powered off" | Out-File .\report.txt -Append}
                    } #end for each VMs loop  

            Remove-Item vm_ip.csv

} #End function CheckRDP


Function Get-UserPass

{
        Param($Host_IP)
        $user = Read-Host -Prompt "Enter Username for $Host_IP " | Out-File ".\Username_$Host_IP.txt"
        $pass = Read-Host -Prompt "Enter Password for $Host_IP " -AsSecureString | ConvertFrom-SecureString | Out-File ".\Password_$Host_IP.txt" 
       
} #End function Get-UserPass


#########################
# Get ESXi host list    #
#########################

    $Hostlist = Get-Content .\List_ESXi_host.txt
    $Host_IP = @()

Foreach ($Host_IP in $Hostlist)
{
 
    echo `n`n`n`n"**********************************************************************************" | Out-File .\report.txt -Append 
    echo `t`t"HOST: $Host_IP" | Out-File .\report.txt -Append 

#########################
# Run the test          #
#########################


    If (((Test-Path .\Password_$Host_IP.txt) -eq $false) -or ((Test-Path .\Username_$Host_IP.txt) -eq $false))
    {
    Get-UserPass $Host_IP
    }
    
        #Get credential to connect
        $userFile = ".\Username_$Host_IP.txt"
        $passFile = ".\Password_$Host_IP.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList (Get-Content $userFile), (Get-Content $passFile | ConvertTo-SecureString)

        #Connect to ESXi host
        Connect-VIServer -Server $Host_IP -Protocol https -Credential $cred -ErrorAction SilentlyContinue

    If ($global:DefaultVIServer -eq $null) 

    {
        Write-Host "Cannot Connect-VIServer to $Host_IP"
        echo "Cannot make a connection use Connect-VIServer to $Host_IP" | Out-File .\report.txt -Append
        $global:connect_failed = $true 
    }
    Else 
    
    {
        Write-Host "Connect-VIServer to $Host_IP successfully"

        #Check for VM power state change

        PowerStateChange $Host_IP

        #Check if all VMs are powered off

        $VMs_on = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState
        If ($VMs_on -eq $null)
        {
        echo "All VMs are powered off: " | Out-File .\report.txt -Append
        $global:VMs_failed = $true
        }
        Else 
        {
            #Check RDP to each powered on VM
            CheckRDP $Host_IP     
        }

        
     }


    #Disconnect ESXi host

    Disconnect-VIServer -Server $Host_IP -Force -Confirm:$false

} #End for each host loop


###########################
# Finalize the process    #
###########################

    #Send report email

    ConvertToHtml -SourceFile .\report.txt -TargetFile .\report.htm
    $content = Get-Content report.htm

    If (($connect_failed) -or ($VMs_failed))
    { 
    Send-MailMessage -to $recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] Warning from Monitor Script" -Credential $mycreds -BodyAsHtml "$content"
    }
    Else 
    {
    Write-Host "Everything is fine"
    }

    #Delete temp files

    Remove-Item .\report.txt
    Remove-Item .\report.htm
