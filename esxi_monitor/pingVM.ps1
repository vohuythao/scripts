
Connect-VIServer -Server 10.9.1.185 -Protocol https -User root -Password P@ssw0rd
Get-VM




$vm = Get-VM -Name Vinh-Sandbox2
if(!(Test-Connection -ComputerName $vm.Guest.HostName -Quiet) -and
    $vm.Guest.State -eq "NotRunning"){
    Stop-VM -VM $vm -Confirm:$false -Kill
    Start-VM -VM $vm
}