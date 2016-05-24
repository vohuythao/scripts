
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

If (Test-Path \\10.9.11.102\cpumem_monitor\last_exec.log)
{

    Copy-Item \\10.9.11.102\cpumem_monitor\last_exec.log

    $compare_time = ((Get-ChildItem .\last_exec.log).LastWriteTime - (Get-ChildItem .\last_state.log).LastWriteTime).TotalMinutes

    Remove-Item .\last_state.log

    Move-Item .\last_exec.log .\last_state.log


    If ($compare_time -gt 0) 
    {
        echo "cpumem_monitor is running"
    }
    Else
    {
        echo "cpumem_monitor is not running"
        Send-MailMessage -to $recipients -from "Watchdog Script <watchdog@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT] cpumem_monitor is not running" -Credential $mycreds -BodyAsHtml "Please check cpumem_monitor script"
    }
}
Else
{
    echo "File last_exec.log does not exist"
}