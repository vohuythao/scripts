Param ($ComputerName, $ServiceName, $AppPool)
$user = "dvnaswig\sarteam"
$filepass = "D:\Apps\Jenkins\scripts\storePassword_sar.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $user, (Get-Content $filepass | ConvertTo-SecureString)
        $session = New-PSSession -Credential $cred -computerName $ComputerName
Invoke-command -Session $session -scriptblock {param($ServiceName) Restart-Service -Name $ServiceName} -ArgumentList $ServiceName
get-pssession | remove-pssession

