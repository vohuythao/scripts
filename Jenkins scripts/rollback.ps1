param([String[]] $ComputerName, [String[]] $Builds, [String[]] $web_server_path)

$user = "dvnaswig\ci_app"
$filepass = "D:\Apps\Jenkins\scripts\storePassword.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $user, (Get-Content $filepass | ConvertTo-SecureString)

 $session = New-PSSession -Credential $cred -computerName $ComputerName
 Invoke-Command -Session $session -ScriptBlock { $datetime = (Get-Date -f yyyyMMdd ) } 
 Invoke-command -Session $session -scriptblock { param($web_server_path) cd $web_server_path } -ArgumentList $web_server_path
 Invoke-command -Session $session -scriptblock { Remove-Item -Recurse .\* -Exclude _backup } 
 Invoke-command -Session $session -scriptblock { param($Builds) unrar x .\_backup\$Builds-bk-*.rar * .} -ArgumentList $Builds
 get-pssession | remove-pssession