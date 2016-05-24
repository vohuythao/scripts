#Email

$smtp_server = "10.9.0.22"
$recipients = "t.vo@aswigsolutions.com"
[string[]]$cc_recipients = "Vinh Nguyen <v.nguyen@aswigsolutions.com>", "Trang Tran <t.minh@aswigsolutions.com>"
$username = "user1@behappy.local"
$password = "password"
$secpasswd = ConvertTo-SecureString "$password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("$username", $secpasswd)


#Check esxi_monitor running
    
    $esxi_monitor_process = Get-WMIObject -Class Win32_Process -Filter "Name='PowerShell.EXE'" | Where {$_.CommandLine -Like "*testrunning*"} 
    
    If ( $esxi_monitor_process.ProcessId -eq $null ) 
    {
    echo "esxi_monitor is not running"
    Send-MailMessage -to $recipients -from "Watchdog Script <watchdog@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] esxi_monitor is not running" -Credential $mycreds -BodyAsHtml "Please check esxi_monitor script"
    }
    Else 
    {
    echo "esxi_monitor is running"
    echo "Execute command" $esxi_monitor_process.CommandLine
    }
#Check cpumem_monitor running

$cpumem_monitor_process = Get-WMIObject -Class Win32_Process -Filter "Name='PowerShell.EXE'" | Where {$_.CommandLine -Like "*cpumem*"} 
    
    If ( $cpumem_monitor_process.ProcessId -eq $null ) 
    {
    echo "cpumem_monitor is not running"
    Send-MailMessage -to $recipients -from "Watchdog Script <watchdog@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] cpumem_monitor is not running" -Credential $mycreds -BodyAsHtml "Please check cpumem_monitor script"
    }
    Else 
    {
    echo "cpumem_monitor is running"
    echo "Execute command" $cpumem_monitor_process.CommandLine
    }