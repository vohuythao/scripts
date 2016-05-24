param([String[]] $ComputerName, [String[]] $Builds, [String[]] $web_server_path, [String[]] $proj_name)

$user = "dvnaswig\ci_app"
$filepass = "D:\Apps\Jenkins\scripts\storePassword.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $user, (Get-Content $filepass | ConvertTo-SecureString)

 $session = New-PSSession -Credential $cred -computerName $ComputerName
 Invoke-Command -Session $session -ScriptBlock { $datetime = (Get-Date -f yyyyMMdd ) } 
 Invoke-command -Session $session -scriptblock { param($web_server_path) cd $web_server_path } -ArgumentList $web_server_path
 Invoke-command -Session $session -scriptblock { param($Builds, $proj_name) rar a -r -x*\_backup\*  .\_backup\$Builds-bk-$proj_name-$datetime.rar .\*} -ArgumentList $Builds, $proj_name
 get-pssession | remove-pssession