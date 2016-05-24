Param ($ComputerName, $AppPool)
$user = "dvnaswig\sarteam"
$filepass = "D:\Apps\Jenkins\scripts\storePassword_sar.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $user, (Get-Content $filepass | ConvertTo-SecureString)
        $session = New-PSSession -Credential $cred -computerName $ComputerName
Invoke-command -Session $session -scriptblock {Import-Module WebAdministration}
Invoke-command -Session $session -scriptblock {cd IIS:\AppPools}
Invoke-command -Session $session -scriptblock {param($AppPool) Stop-WebAppPool -Name $AppPool} -ArgumentList $AppPool
get-pssession | remove-pssession