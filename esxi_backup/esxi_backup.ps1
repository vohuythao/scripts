 #Working directory, must contain "monitorscript.ps1", "information.csv"

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

cd $scriptPath

 #Variables declaration

 $savedir = "$scriptPath\Backup_Repo"
 $datetime = (Get-Date -f dd_MM_yyyy)

 #Email

$smtp_server = "10.9.0.22"
$recipients = "t.vo@aswigsolutions.com"
[string[]]$cc_recipients = "Vinh Nguyen <v.nguyen@aswigsolutions.com>", "Trang Tran <t.minh@aswigsolutions.com>"
$username = "user1@behappy.local"
$password = "password"
$secpasswd = ConvertTo-SecureString "$password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("$username", $secpasswd)

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

#########################
# Run the backup process#
#########################

    
        #Get credential to connect

        $filepass = ".\temppassword_$Host_IP.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $user, (Get-Content $filepass | ConvertTo-SecureString)

        #Connect to ESXi host
        Write-Host "Connecting to ESXi host $Host_IP" -foreground green
        Connect-VIServer -Server $Host_IP -Protocol https -Credential $cred -ErrorAction SilentlyContinue

        If ($global:DefaultVIServer -eq $null) 
        {
            Write-Host "Cannot Connect-VIServer to $Host_IP" -ForegroundColor Red
            echo "Cannot make a connection use Connect-VIServer to $Host_IP"
            $global:connect_failed = $true 
        }
        Else    
        {
            Write-Host "Connect-VIServer to $Host_IP successfully" -ForegroundColor Green
        }
       
        #Backup
        Write-Host "Backing Up Host Configuration: $Host_IP" -foreground green
        Get-VMHostFirmware -VMHost $Host_IP -BackupConfiguration -DestinationPath $savedir 
        
        #Rename backup file
        Get-ChildItem $savedir\*.tgz |Rename-Item -NewName {$_.BaseName+"_"+($datetime)+$_.Extension}
       
        #Move backup file
        Move-item -path $savedir\*tgz -destination $savedir\$Host_IP

        #Delete old files
        $list = (Get-ChildItem $savedir\$Host_IP).Name

        foreach ($file in $list)
        {
            $compare_time = ((Get-Date) - (Get-ChildItem $savedir\$Host_IP\$file).LastWriteTime).TotalDays
            If ($compare_time -gt 30)
            {
                Remove-Item $savedir\$Host_IP\$file
                Write-Host "Remove $file follow the retention policy" -ForegroundColor Cyan
            }
        }

        #Disconnect ESXi host

        Disconnect-VIServer -Server $Host_IP -Force -Confirm:$false
        Remove-Item .\temppassword_$Host_IP.txt

        }#End for each host loop
} #End if exist Information.csv

Else 
{
Write-Host "Cannot find information.csv, please check again!!!" -ForegroundColor DarkRed
}