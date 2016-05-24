param([String[]] $Builds, [String[]] $proj_name)

$user = "dvnaswig\ci_app"
$filepass = "D:\Apps\Jenkins\scripts\storePassword.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $user, (Get-Content $filepass | ConvertTo-SecureString)

 $session = New-PSSession -Credential $cred -computerName dvnci01
 Invoke-command -Session $session -scriptblock { param($Builds, $proj_name) cd D:\Artifact_Repository\$proj_name\$Builds} -ArgumentList $Builds, $proj_name
 Invoke-command -Session $session -scriptblock { unrar x .\package_*.zip}
 get-pssession | remove-pssession