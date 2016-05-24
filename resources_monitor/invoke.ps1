Import-Csv .\local_info_1.csv |
foreach {
$local_user = $_.username
$local_pass = $_.password | Out-File .\local_temppassword.txt
$local_filepass = ".\local_temppassword.txt"
$local_cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $local_user, (Get-Content $local_filepass | ConvertTo-SecureString)
Invoke-VMScript -VM Vinh-Sandbox2 -GuestCredential $local_cred -ScriptText "stop-computer" -ScriptType Powershell    
} 