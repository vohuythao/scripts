
#Working directory

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

cd $scriptPath

#Email

$smtp_server = "10.9.0.22"
$recipients = "t.vo@aswigsolutions.com"
[string[]]$cc_recipients = "Vinh Nguyen <v.nguyen@aswigsolutions.com>", "Trang Tran <t.minh@aswigsolutions.com>"
$username = "user1@behappy.local"
$password = "password"
$secpasswd = ConvertTo-SecureString "$password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("$username", $secpasswd)

#Running

If (Test-Path \\10.9.11.102\esxi_monitor\last_exec.log)
{

    $compare_time = ((Get-Date) - (Get-ChildItem \\10.9.11.102\esxi_monitor\last_exec.log).LastWriteTime).TotalMinutes

    If ($compare_time -gt 17) 
    {
        echo "esxi_monitor is not running"
        Send-MailMessage -to $recipients -from "Watchdog Script <watchdog@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] esxi_monitor is not running" -Credential $mycreds -BodyAsHtml "Please check esxi_monitor script"
    }
    Else
    {
        echo "esxi_monitor is running"
    }
}
Else
{
    echo "File last_exec.log does not exist"
}