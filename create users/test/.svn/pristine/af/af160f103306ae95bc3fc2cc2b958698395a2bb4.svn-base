 param(
 [string]$working_space
 )
 #Working directory

 #$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

 cd $working_space

 switch -wildcard ($working_space) 
    { 
        "*\PreQA*" {$environment = "PreQA"} 
        "*\QA*" {$environment = "QA"} 
        "*\DEV*" {$environment = "DEV"} 
        default {"The environment could not be determined."}
    }

 #Set threshold (percentage)

 $threshold_cpu = 90
 $threshold_mem = 90
 $threshold_disk = 200
 
 #Email

$smtp_server = "10.9.0.22"
$recipients = "t.vo@aswigsolutions.com"
[string[]]$cc_recipients = "Vinh Nguyen <v.nguyen@aswigsolutions.com>", "Trang Tran <t.minh@aswigsolutions.com>"
$username = "user1@behappy.local"
$password = "password"
$secpasswd = ConvertTo-SecureString "$password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("$username", $secpasswd)

#Test variable

$global:overload_failed = $false

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


Function CheckCPUMemDisk
{
    Param($Host_IP)
   
    #Check memory and CPU status of each powered on VM

    #Get-VM | Select Name, PowerState, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolstatus";E={@($_.ExtensionData.Guest.ToolsVersionStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}} | Export-Csv vm_ip.csv -NoTypeInformation

    #Import-Csv vm_ip.csv |  

    ForEach ($VM in Get-VM | where-object {($_.powerstate -ne "PoweredOff") -and ($_.Extensiondata.Guest.ToolsStatus -Match ".*Ok.*")}){

    $IP = $VM.guest.IPAddress[0]
    $Names = $VM.Name
        If ($VM.PowerState -eq "PoweredOn")
        {
            $stats = Get-Stat -Entity $Names -MaxSamples 1 -Stat "cpu.usage.average","mem.usage.average" 
            $cpu = $stats| where {$_.MetricID -eq "cpu.usage.average"}
            $mem = $stats| where {$_.MetricID -eq "mem.usage.average"}
            $cpuvalue = $cpu.Value
            $memvalue = $mem.Value
            If (($cpuvalue -eq 0) -or ($memvalue -eq 0) -or ((Get-Content .\exclude.txt).Contains($Names)))
            {
            Write-Host "$Names - Value of CPU or memory is not correct or $Names is in the excluded list, try again later"
            }
            Else
            {
                echo "$Names - $IP got CPU $cpuvalue% and memory $memvalue%"
                    If (($cpuvalue -gt $threshold_cpu) -or ($memvalue -gt $threshold_mem)) 
                    { 
                    Write-Host "$Names - $IP got overload : CPU $cpuvalue% and memory $memvalue%"
                    echo "$Names - $IP got overload : CPU $cpuvalue% and memory $memvalue%" | Out-File .\report_$Host_IP.txt -Append
                    #Send-MailMessage -to $recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] VM $Names got overload" -Credential $mycreds -BodyAsHtml "VM $Names got overload : CPU $cpuvalue% and RAM $memvalue%"
                    $global:overload_failed = $true
                    }   
            ForEach ($Drive in $VM.Extensiondata.Guest.Disk) {
 
            $Path = $Drive.DiskPath
 
            #Calculations 
            $Freespace = [math]::Round($Drive.FreeSpace / 1MB)
            $Capacity = [math]::Round($Drive.Capacity/ 1MB)
            $PercentFree = [math]::Round(($FreeSpace)/ ($Capacity) * 100) 
 
            #VMs with less space
            echo "Disk $Path of $Names - $IP has $Freespace free, $PercentFree"
            if ($Freespace -lt $threshold_disk) 
                { 
                    echo "Disk $Path of $Names - $IP is full, $Freespace MB free"    
                    echo "Disk $Path of $Names - $IP is full, $Freespace MB free" | Out-File .\report_$Host_IP.txt -Append  
                    $global:overload_failed = $true 
                    Import-Csv .\local_info.csv |
                    foreach {
                    $local_user = $_.username
                    $local_pass = $_.password | Out-File .\local_temppassword.txt
                    $local_filepass = ".\local_temppassword.txt"
                    $local_cred = New-Object -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList $local_user, (Get-Content $local_filepass | ConvertTo-SecureString)  
                    ## CCleaner portable is located in DVNMOM01 - 10.9.11.102 
                    Invoke-VMScript -VM $Names -GuestCredential $local_cred -ScriptText "Start-Process \\10.9.11.102\script\Software\CCleaner\CCleaner64.exe /AUTO -Verb RunAs" -ScriptType Powershell  
                    Invoke-VMScript -VM $Names -GuestCredential $local_cred -ScriptText "rd /s /q c:\$Recycle.Bin" -ScriptType Bat
                    Remove-Item .\local_temppassword.txt
                            }  
                }
 
              } # End ForEach ($Drive in in $VM.Extensiondata.Guest.Disk)
  
            }
            
        }
        Else 
        {
            echo "$Names is powered off" 
        }

    } #End VMs loop
    #Remove-Item vm_ip.csv
} #End function CheckCPUMemDisk

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
    }
    Else    
    {
        Write-Host "Connect-VIServer to $Host_IP successfully"

        #Check if all VMs are powered off

        $VMs_on = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState
        If ($VMs_on -eq $null)
        {
            Write-Host "All VMs are powered off "
        }
        Else 
        {
            #Check CPU and memory overload
            CheckCPUMemDisk $Host_IP     
        }  
     }

        #Disconnect ESXi host

        Disconnect-VIServer -Server $Host_IP -Force -Confirm:$false
        Remove-Item .\temppassword_$Host_IP.txt

} # end foreach host loop

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
        If (((Get-Content $file | Select-String "overload") -ne $null) -or ((Get-Content $file | Select-String "full") -ne $null))
        {
            Get-Content $file | Out-File .\finalreport.txt -Append
        }
    }
    ConvertToHtml -SourceFile .\finalreport.txt -TargetFile .\finalreport.htm
    $content = Get-Content finalreport.htm

    If ($overload_failed)
    { 
        Send-MailMessage -to $recipients -Cc $cc_recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] [$environment] VM resources monitoring" -Credential $mycreds -BodyAsHtml "$content"
    }
    Else 
    {
        Write-Host "Everything is fine"
    }

    #Delete temporary files

    Remove-Item .\report*.txt
    Remove-Item .\finalreport.txt
    Remove-Item .\finalreport.htm
    echo (Get-Date) | Out-File last_exec.log