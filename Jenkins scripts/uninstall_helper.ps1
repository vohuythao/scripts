Param ($ComputerName, $software)
$ErrorActionPreference = "Stop"
## account to execute the process ##
$user = "dvnaswig\sarteam"
$filepass = "D:\Apps\Jenkins\scripts\storePassword_sar.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $user, (Get-Content $filepass | ConvertTo-SecureString)
## Start the installation ## 
      
$session = New-PSSession -Credential $cred -computerName $ComputerName
Invoke-Command -Session $session -ScriptBlock {param($software)

$app = Get-WmiObject -Class Win32_Product -Filter "Name = '$software'"
$app.Uninstall()
} -ArgumentList $software
Exit-PSSession
Get-PSSession | Remove-PSSessionApp