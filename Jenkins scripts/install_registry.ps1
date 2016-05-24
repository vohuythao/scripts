param([String[]] $ComputerName)

$user = "dvnaswig\ci_app"
$filepass = "D:\Apps\Jenkins\scripts\storePassword.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $user, (Get-Content $filepass | ConvertTo-SecureString)

 $session = New-PSSession -Credential $cred -computerName $ComputerName
 Invoke-Command -Session $session -ScriptBlock { Remove-Item -Path HKCU:\Software\hsg }
 Invoke-Command -Session $session -ScriptBlock { New-Item -Path HKCU:\Software -Name hsg -Value "scripted default value" }
 get-pssession | remove-pssession