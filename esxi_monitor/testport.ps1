###########################################################################################
# Title:	ESXi and VMs monitor script 
# Filename:	monitorscript.sp1       	
# Created by:	Thao Vo t.vo@aswigsolutions.com			
# Date:		18-05-2015					
# Version       1.0					
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
#
#   1.Browse to the working directory where the monitorscript.ps1 script resides
#   2.Create a txt file, name "List_ESXi_host.txt", each line is IP address of each ESXi host
#   3.Create a folder name "scriptlog" for contain the log file
#   4.Edit the monitorscript.ps1 file and fill in the blank variables in Variable declaration
#  
###########################################################################################
# Usage:
#
#   Manually run the monitorscipt.ps1 script":
#   
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


# Threshold definition

$threshold_cpu = @()
$threshold_mem = @()



#########################
# Variable declaration  #
#########################
    #Working directory, that must contain "monitorscript.ps1", "List_ESXi_host.txt", and folder "scriptlog"

    $path = "C:\"

    #Email

$smtp_server = "10.9.0.22"
$recipients = "t.vo@aswigsolutions.com"
$username = "user1@behappy.local"
$password = "password"
$secpasswd = ConvertTo-SecureString "$password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("$username", $secpasswd)

    #ESXi username and password

$vcuser = "root"
$vcpassword = "P@ssw0rd"

    #Test variable
$global:ping_failed = $false
$global:connect_failed = $false
$global:VMs_failed = $false


##########################
# Move to working folder #
##########################

cd $path 

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
    Send-MailMessage -to $recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] ESXi host $Host_IP got problem" -Credential $mycreds -BodyAsHtml "Cannot ping to ESXi host $Host_IP"
    }

} #End function TestPing


#########################
# Get ESXi host list    #
#########################

$Hostlist = Get-Content .\List_ESXi_host.txt
$Host_IP = @()

Foreach ($Host_IP in $Hostlist)
{

echo `n`n"**********************************************************************************" | Out-File .\ip_failed.txt -Append
echo `t`t"ESXi HOST $Host_IP" | Out-File .\ip_failed.txt -Append

#########################
# Run the test          #
#########################

    #Test ping 

TestPing $Host_IP

    #Connect to ESXi host

Connect-VIServer -Server $Host_IP -Protocol https -User $vcuser -Password $vcpassword


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
        $stats = Get-Stat -Entity $Names -MaxSamples 1 -Stat "cpu.usage.average","mem.usage.average"
        $stats | Group-Object -Property Entity | %{
        $vmstat = "" | Select VmName, MemMax, MemAvg, MemMin, CPUMax, CPUAvg, CPUMin
        $vmstat.VmName = $_.name
        $cpu = $_.Group | where {$_.MetricId -eq "cpu.usage.average"} | Measure-Object -Property value
        $mem = $_.Group | where {$_.MetricId -eq "mem.usage.average"} | Measure-Object -Property value
        }

        }
        Else {}
    }
    Else 
    {Write-Host "Host $Host_IP - Cannot get IP of $Names"; 
    echo "Host $Host_IP - Cannot get IP of $Names" | Out-File C:\ip_failed.txt -Append
    }
}  

Remove-Item vm_ip.csv

    #Disconnect all ESXi host

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

ConvertToHtml -SourceFile $filename_failed -TargetFile .\ip_failed.htm
$content = Get-Content ip_failed.htm

If (($ping_failed) -or ($connect_failed) -or ($VMs_failed))
{ 
Send-MailMessage -to $recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] Warning from Monitor Script" -Credential $mycreds -BodyAsHtml "$content"
}
Else {}

    #Delete temp files and move to log folder

Move-Item $filename_failed .\scriptlog
Move-Item $filename_success .\scriptlog
Remove-Item .\ip_failed.htm

