$VMs_on_before = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState | Out-File VMbefore.txt

Sleep 60

$VMs_on_after = Get-VM | where {$_.PowerState -eq "PoweredOn"} | Select Name, PowerState | Out-File VMafter.txt
If ((Get-Content VMafter.txt) -eq $null)
{ 

Get-VM | where {$_.PowerState -eq "PoweredOff"} | Select Name, PowerState

}
Else
{
$result = Compare-Object (Get-Content VMbefore.txt) (Get-Content VMafter.txt)
$result.InputObject -split "\s+" | select-string -pattern "PoweredOn" -notmatch | where {$_ -ne ""}
}
