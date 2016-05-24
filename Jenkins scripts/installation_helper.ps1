Param ($ComputerName, $filepath, [String[]] $arg, $type)
$ErrorActionPreference = "Stop"
## account to execute the process ##
$user = "dvnaswig\sarteam"
$filepass = "D:\Apps\Jenkins\scripts\storePassword_sar.txt"
        $cred = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $user, (Get-Content $filepass | ConvertTo-SecureString)


## Start the installation ## 
function MSI_installation
{
$session = New-PSSession -Credential $cred -computerName $ComputerName 
Invoke-Command -Session $session -ScriptBlock {param($arg) Start-Process -FilePath "msiexec.exe" -ArgumentList $arg -Wait} -ArgumentList $arg
Exit-PSSession
}

function PS1_installation
{
$session = New-PSSession -Credential $cred -computerName $ComputerName 
Invoke-Command -Session $session -ScriptBlock {param($arg) Start-Process -FilePath "powershell.exe" -ArgumentList $arg -Wait} -ArgumentList $arg
Exit-PSSession
}

function EXE_installation
{
$session = New-PSSession -Credential $cred -computerName $ComputerName 
Invoke-Command -Session $session -ScriptBlock {param($filepath, $arg) Start-Process -FilePath "$filepath" -ArgumentList $arg -Wait} -ArgumentList $filepath, $arg
Exit-PSSession
}


switch -Exact ($type) 
    { 
        "msi" {MSI_installation} 
        "ps1" {PS1_installation} 
        "exe" {EXE_installation} 
        default {"The file type could not be determined."}
    }