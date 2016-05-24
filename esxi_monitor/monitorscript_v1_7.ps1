###########################################################################################
# Title:	ESXi and VMs monitor script 
# Filename:	monitorscript.sp1       	
# Created by:	Thao Vo t.vo@aswigsolutions.com			
# Date:		11-06-2015					
# Version       1.7		
# - Reduce the report email content		
###########################################################################################
# Description:	Scripts that monitor the status of a VMware      
# enviroment on the following point:		
# - Check the Connect-VIServer command to connect to ESXi host	       					
# - Monitor the power state of each VMs in every ESXi hosts			
# - If get any failure, send cumulative alert email after x minutes		
###########################################################################################
# Configuration:
#   1.Browse to the working directory where the monitorscript.ps1 script resides, create a csv file, name "information.csv", 1st column is host_ip. 2nd column is username, 3rd column is encrypted password
#   How to create encrypted password:
#   "your ESXi host password" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString > password.csv
#   and copy the code in output password.csv file to password column in information.csv
#   2.Open powershell, type :
#        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
#        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
#        Set-PowerCLIConfiguration -ProxyPolicy NoProxy -Confirm:$false
#   3.Edit the monitorscript.ps1 file and fill in the blank variables in Variable declaration - Email
#   4.When the script ask for username/password for connecting ESXi host, just type 1 time 
###########################################################################################
# Usage:
#   Manually run the monitorscipt.ps1 script": 
#   1.Browse to the directory where the monitorscript.ps1 script resides
#   2.Open powershell
#   5.Enter the command:
#   .\monitorscript.ps1
#   To create a schedule task use the following 
#   syntax in the run property:
#   powershell -file "path\monitorscript.ps1" 
###########################################################################################

##########################
# Move to working folder #
##########################

    #Working directory, must contain "monitorscript.ps1", "information.csv"

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

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
$global:All_VMs_off = $false

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
            Write-Host "Connecting to $Names "$VMs":"$Port" (TCP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Host "Connection successful";
            echo "Connect successfully to $Names - $VMs port $Port" 
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $Names - $VMs port $Port"  
            echo "Cannot connect to $Names - $VMs port $Port" | Out-File .\report_$Host_IP.txt -Append 
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
            Write-Host "Connecting to $Names "$VMs":"$Port" (UDP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Host "Connection successful";
            echo "Connect successfully to $Names - $VMs port $Port" 
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $Names - $VMs port $Port"  
            echo "Cannot connect to $Names - $VMs port $Port" | Out-File .\report_$Host_IP.txt -Append 
            $global:connect_failed = $true
            
        }
        Finally
        {
            $test.Dispose();
        }
    }
} #End function TestPort-VM

Function CheckRDP
{
    Param($Host_IP)
    Get-VM | Select Name, PowerState, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolstatus";E={@($_.ExtensionData.Guest.ToolsVersionStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}} | Export-Csv vm_ip.csv -NoTypeInformation

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
                Else
                {
                    Write-Host "Cannot get IP of $Names, use VMs name instead" 
                    TestPort-VM -ComputerName $Names -Port 3389 -Protocol TCP
                }
                
            }
            Else 
            {
                echo "$Names is powered off" | Out-File .\report_$Host_IP.txt -Append
            }
    } #end for each VMs loop  

            Remove-Item vm_ip.csv

} #End function CheckRDP

#########################
# Get ESXi host list    #
#########################

If (Test-Path .\information.csv)
{

    Import-Csv .\information.csv |  
    foreach {  
        $Host_IP = $_.host_ip
        $user = $_.username
        $pass = $_.password | Out-File .\temppassword_$Host_IP.txt
        
    echo `n`n`n`n"**********************************************************************************" | Out-File .\report_$Host_IP.txt -Append 
    echo `t`t"HOST: $Host_IP" | Out-File .\report_$Host_IP.txt -Append 

#########################
# Run the test          #
#########################

    
        #Get credential to connect

        $filepass = ".\temppassword_$Host_IP.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $user, (Get-Content $filepass | ConvertTo-SecureString)

        #Connect to ESXi host

        Connect-VIServer -Server $Host_IP -Protocol https -Credential $cred -ErrorAction SilentlyContinue

        If ($global:DefaultVIServer -eq $null) 
        {
            Write-Host "Cannot Connect-VIServer to $Host_IP"
            echo "Cannot make a connection use Connect-VIServer to $Host_IP" | Out-File .\report_$Host_IP.txt -Append
            $global:connect_failed = $true 
        }
        Else    
        {
            Write-Host "Connect-VIServer to $Host_IP successfully"

            #Check if all VMs are powered off

            $VMs_on = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState
            If ($VMs_on -eq $null)
            {
                Write-Host "All VMs are powered off "
                echo "All VMs are powered off " | Out-File .\report_$Host_IP.txt -Append
                $global:All_VMs_off = $true
            }
            Else 
            {
                #Check RDP to each powered on VM
                CheckRDP $Host_IP     
            }  
        }

        #Disconnect ESXi host

        Disconnect-VIServer -Server $Host_IP -Force -Confirm:$false
        Remove-Item .\temppassword_$Host_IP.txt

    } #End for each host loop

} #End if exist Information.csv

Else 
{
Write-Host "Cannot find information.csv, please check again!!!"
}

###########################
# Finalize the process    #
###########################

    #Send report email

    echo (Get-Date) | Out-File .\finalreport.txt -Append
    $file = @()
    foreach ($file in (Get-ChildItem report*).Name)
    {
        If (((Get-Content $file | Select-String "Cannot") -ne $null) -or ((Get-Content $file | Select-String "powered off") -ne $null))
        {
            Get-Content $file | Out-File .\finalreport.txt -Append
        }
    }
    ConvertToHtml -SourceFile .\finalreport.txt -TargetFile .\finalreport.htm
    $content = Get-Content finalreport.htm

    If (($connect_failed) -or ($global:All_VMs_off))
    { 
        Send-MailMessage -to $recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] ESXi host monitoring" -Credential $mycreds -BodyAsHtml "$content"
    }
    Else 
    {
        Write-Host "Everything is fine"
    }

    #Delete temporary files
    Remove-Item .\report*.txt
    Remove-Item .\finalreport.txt
    Remove-Item .\finalreport.htm