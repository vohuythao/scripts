param([String[]] $ComputerName)

$user = "dvnaswig\ci_app"
$filepass = "D:\Apps\Jenkins\scripts\storePassword.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $user, (Get-Content $filepass | ConvertTo-SecureString)

 $session = New-PSSession -Credential $cred -computerName $ComputerName
 Invoke-Command -Session $session -ScriptBlock { msiexec /x "C:\Temp\7z938-x64.msi" /qn /log "C:\Temp\7z938-x64.log" } 
 Invoke-Command -Session $session -ScriptBlock { msiexec /i "C:\Temp\7z938-x64.msi" /qn /log "C:\Temp\7z938-x64.log" }
 get-pssession | remove-pssession
 