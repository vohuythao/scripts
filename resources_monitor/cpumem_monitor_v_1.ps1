 #Working directory, that must contain "monitorscript.ps1", "List_ESXi_host.txt"

 $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

 cd $scriptPath

 #Set threshold

 $threshold_cpu = 90
 $threshold_mem = 90
 
 #Email

$smtp_server = "10.9.0.22"
$recipients = "t.vo@aswigsolutions.com"
[string[]]$cc_recipients = "Vinh Nguyen <v.nguyen@aswigsolutions.com>", "Trang Tran <t.minh@aswigsolutions.com>"
$username = "user1@behappy.local"
$password = "password"
$secpasswd = ConvertTo-SecureString "$password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("$username", $secpasswd)

#Test variable

$global:ping_failed = $false

#########################
# Function declaration  #
#########################

Function Get-UserPass

{
        Param($Host_IP)
        $user = Read-Host -Prompt "Enter Username for $Host_IP " | Out-File ".\Username_$Host_IP.txt"
        $pass = Read-Host -Prompt "Enter Password for $Host_IP " -AsSecureString | ConvertFrom-SecureString | Out-File ".\Password_$Host_IP.txt" 
       
} #End function Get-UserPass
Function TestPing
{

Param($Host_IP)

If (Test-Connection $Host_IP -Quiet) 
    {
    Write-Host "Ping host $Host_IP successfully";
    }
Else
    {
    Write-Host "Cannot ping host $Host_IP";
    $global:ping_failed = $true
    Send-MailMessage -to $recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] ESXi host $Host_IP got problem" -Credential $mycreds -BodyAsHtml "Cannot ping to ESXi host $Host_IP"
    }

} #End function TestPing


#########################
# Get ESXi host list    #
#########################

$time = 1

do {

$Hostlist = Get-Content .\List_ESXi_host.txt
$Host_IP = @()

Foreach ($Host_IP in $Hostlist)
{

#########################
# Run the test          #
#########################


    #Test ping 

    TestPing $Host_IP

    #Get credential to connect

    If (((Test-Path .\Password_$Host_IP.txt) -eq $false) -or ((Test-Path .\Username_$Host_IP.txt) -eq $false))
    {
        Get-UserPass $Host_IP
    }
        $userFile = ".\Username_$Host_IP.txt"
        $passFile = ".\Password_$Host_IP.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList (Get-Content $userFile), (Get-Content $passFile | ConvertTo-SecureString)
   #Connect to ESXi host

    Connect-VIServer -Server $Host_IP -Protocol https -Credential $cred -ErrorAction SilentlyContinue

    If ($global:DefaultVIServer -eq $null) 

    {
        Write-Host "Cannot Connect-VIServer to $Host_IP"
        echo "Cannot make a connection use Connect-VIServer to $Host_IP" 
        $global:connect_failed = $true 
    }
    Else 
    {
        Write-Host "Connect-VIServer to $Host_IP successfully"
    }

    #Check memory and CPU status of each powered on VM

Get-VM | Select Name, PowerState, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolstatus";E={@($_.ExtensionData.Guest.ToolsVersionStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}} | Export-Csv vm_ip.csv -NoTypeInformation

Import-Csv vm_ip.csv |  
foreach {  
    $VMs = $_.ip
    $Names = $_.Name
    If ($_.PowerState -eq "PoweredOn")
    {
  
        $stats = Get-Stat -Entity $Names -MaxSamples 1 -Stat "cpu.usage.average","mem.usage.average" -IntervalSecs 60
        $cpu = $stats| where {$_.MetricID -eq "cpu.usage.average"}
        $mem = $stats| where {$_.MetricID -eq "mem.usage.average"}
        $cpuvalue = $cpu.Value
        $memvalue = $mem.Value
        echo "$Names - $VMs got CPU $cpuvalue% and memory $memvalue%"
            If (($cpuvalue -gt $threshold_cpu) -or ($memvalue -gt $threshold_mem)) 
            { 
            echo "VM $Names got overload : CPU $cpuvalue% and RAM $memvalue%"
            Send-MailMessage -to $recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] VM $Names got overload" -Credential $mycreds -BodyAsHtml "VM $Names got overload : CPU $cpuvalue% and RAM $memvalue%"
            }     
    }
    Else 
    {
    echo "$Names is powered off" 
    }
    
}  # end foreach VM loop

Remove-Item vm_ip.csv


    #Disconnect ESXi host

Disconnect-VIServer -Server $Host_IP -Force -Confirm:$false

} # end foreach host loop

$time++

} until ($global:ping_failed -eq $true) 

 
#end do loop