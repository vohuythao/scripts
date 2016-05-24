#Get services that should be started (StartMode = Auto) but are stopped (State = Stopped), then start these services 
$service_name = "BTSSvc`$BizTalkServerApplication"
Get-WmiObject -class Win32_Service -computername . -namespace "root\CIMV2" | Where-Object {$_.Name -match $service_name -and $_.StartMode -match "auto" -and $_.state -match "stopped"} | Start-Service