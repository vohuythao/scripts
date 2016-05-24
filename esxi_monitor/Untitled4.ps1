## Check for VM powerstate change

$VMs_on_before = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState | Out-File VMbefore.txt

$result1 = Compare-Object (Get-Content VMlasttime.txt) (Get-Content VMbefore.txt)

Sleep 60

$VMs_on_after = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState | Out-File VMafter.txt

$result2 = Compare-Object (Get-Content VMbefore.txt) (Get-Content VMafter.txt)

Move-Item VMafter.txt VMlasttime.txt -Force

If (($result1 -eq $null) -and ($result2 -eq $null))
{}
Else
{
$VMs_just_off1 = $result1.InputObject -split "\s+" | select-string -pattern "PoweredOn" -notmatch | where {$_ -ne ""}
$VMs_just_off2 = $result2.InputObject -split "\s+" | select-string -pattern "PoweredOn" -notmatch | where {$_ -ne ""}
$VMs_failed = $true
} 

Remove-Item C:\VMbefore.txt