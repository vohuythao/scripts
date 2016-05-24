
## Email information

$secpasswd = ConvertTo-SecureString "password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("user1@behappy.local", $secpasswd)


$SourceFile = "C:\ip_success.log"
$TargetFile = "C:\ip_success.htm"

$File = Get-Content $SourceFile
$FileLine = @()
Foreach ($Line in $File) {
 $MyObject = New-Object -TypeName PSObject
 Add-Member -InputObject $MyObject -Type NoteProperty -Name Mot -Value $Line
 $FileLine += $MyObject
}
$FileLine | ConvertTo-Html -Property Hai -body "<H2>Ba</H2>" | Out-File $TargetFile

$content = Get-Content $TargetFile

Send-MailMessage -to t.vo@aswigsolutions.com -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer 10.9.0.22 -Subject "Report from Monitor Script" -Credential $mycreds -BodyAsHtml "$content"