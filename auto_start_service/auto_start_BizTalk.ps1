[string[]]$service_name = "BTSSvc`$BizTalkServerApplication"

#Email

$smtp_server = "10.9.0.22"
$recipients = "t.vo@aswigsolutions.com"
[string[]]$cc_recipients = "Vinh Nguyen <v.nguyen@aswigsolutions.com>", "Trang Tran <t.minh@aswigsolutions.com>"
$username = "user1@behappy.local"
$password = "password"
$secpasswd = ConvertTo-SecureString "$password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("$username", $secpasswd)

#Check the service status
$time = 0
do {
$service = Get-WmiObject -class Win32_Service -computername . -namespace "root\CIMV2" | Where-Object {$_.Name -match $service_name -and $_.StartMode -match "auto"} 

If ($service.State -match "Stopped")
{
    Start-Service -Name $service_name
    sleep 120
}
    $time++
}   until ($time -eq 2) 

$3rd_check = Get-WmiObject -class Win32_Service -computername . -namespace "root\CIMV2" | Where-Object {$_.Name -match $service_name -and $_.StartMode -match "auto"} 
If ($3rd_check.State -match "Stopped")
{
    Send-MailMessage -to $recipients -from "Services Monitor <servicesmonitor@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[Information] BizTalk service in PreQA SYDBT001 is restarted" -Credential $mycreds -BodyAsHtml "BizTalk service in PreQA SYDBT001 is auto started"
}
