<#
   .AUTHOR
     Nguyen Minh Thanh
   .SYNOPSIS 
     Script to Shutdown, Start or Reconfigure VM-settings
   .SYNTAX
     VM_config.ps1 -Task [Up|Down] 
   .PARAMETER
      Task:        Shutdown or Start VMs (must be exactly one of this Up|Down)
      FilePath:    Input location of config file
   .NOTE
      Up: Start VMs
      Down: Shutdown VMs
   .EXAMPLE
     D:\Script\VM_config.ps1 -Task Down -FilePath 'D:\script\server.txt'
     Setup Task Scheduler:
            -Program/Script: powershell.exe
            -Argument(optional): -command "D:\Script\VM_config.ps1 -Task Up -FilePath 'D:\script\server.txt'"
                      
#>
param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('Up','Down')]
		[string]$Task,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$FilePath
       )
$info = Get-Content $FilePath -raw | ConvertFrom-Json
foreach ( $server in $info.hosts)`
{ 
$passwd = $server.password | ConvertTo-SecureString # $server.password = ConvertTo-SecureString "password" -AsPlainText -Force | Convertfrom-SecureString
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $server.user,$passwd
Connect-VIServer -Server $server.host -Credential $cred -Force 
If($Task -eq 'Down')
    {
        foreach ($i in $server.simple)
            {
                Shutdown-VMGuest $i.server -Confirm:$False -ErrorAction SilentlyContinue
            }
    }
Else{
        foreach ($i in $server.simple)
            {
                Start-VM $i.server -ErrorAction SilentlyContinue
            }
    }


foreach ($i in $server.complex)
    {
       
       $VMget =get-vm $i.server
       if ($VMGet.Powerstate -eq "PoweredOn" -and $VMget.Guest.State -ne "toolsNotInstalled")`
        {
         Shutdown-VMGuest $VMget.Name -Confirm:$False -ErrorAction SilentlyContinue                                                                                
         do {                                                                                                               
             Write-Host "Waiting on shutdown for VM"                                                                                                                                                                                                                                                                                                          
             sleep 5                                                                                                                                                                                                                                                                                                                 
            }until((get-vm $VMget.Name).Powerstate -eq "PoweredOff")
        }
       Set-VM $VMget.Name -MemoryGB $i.memory -NumCpu $i.cpu  –Confirm:$False
       Start-VM  $VMget.Name  -ErrorAction SilentlyContinue
    }
 Disconnect-VIServer   -Confirm:$false
 }