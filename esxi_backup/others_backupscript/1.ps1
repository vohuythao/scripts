$savedir = "c:\CriticalConfigs\ESXiHosts"
$archivedir = "c:\CriticalConfigs\ESXiHosts\Archive"
$datetime = (Get-Date -f dd_MM_yy)
$VCServer = "Virtual_Center_Hostname"
 
Function ArchiveExisting {
Move-item -path $savedir\*tgz -destination $archivedir }
 
Function DoBackup {
Connect-VIServer $VCServer
Get-VMHost | Get-VMHostFirmware -BackupConfiguration -DestinationPath $savedir }
 
Function RenameBackup {
Get-ChildItem $savedir\*.tgz |Rename-Item -NewName {$_.BaseName+"_"+($datetime)+$_.Extension}}
 
Function EmailResults {
$MsgBody = (gci c:\CriticalConfigs\ESXiHosts | select-object Name, LastWriteTime |ft |out-string)
send-mailmessage -from "ESXiBackups@domain.com.au" -to "recipient@domain.com.au" -subject "ESXi Host Backups complete" -body "$MsgBody" -SmtpServer mailserver@domain.com.au }
 
ArchiveExisting
DoBackup
RenameBackup
EmailResults