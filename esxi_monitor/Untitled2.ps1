
$ping_fail = $false
Function TestPing
{

Param($hosts_ip)

If (Test-Connection $hosts_ip -Quiet) 
    {
    Write-Host "Ping host $hosts_ip sucessfully";
    echo "Ping successfully to $hosts_ip" | Out-File C:\ip_success.txt -Append -Width 120
    }
Else
    {
    Write-Host "Cannot ping host $hosts_ip";
    echo "Cannot ping to $hosts_ip" | Out-File C:\ip_failed.txt -Append
    $ping_fail = $true
    Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "[ALERT] ESXi host $hosts_ip got problem" -Credential $mycreds -BodyAsHtml "Cannot ping to ESXi host $hosts_ip"
    }

} ## End function TestPing

TestPing 10.9.1.185