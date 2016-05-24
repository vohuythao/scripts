##Function declaration

function TestPort
{
    Param(
        [parameter(ParameterSetName='ComputerName', Position=0)]
        [string]
        $ComputerName,

        [parameter(ParameterSetName='IP', Position=0)]
        [System.Net.IPAddress]
        $IPAddress,

        [parameter(Mandatory=$true , Position=1)]
        [int]
        $Port,

        [parameter(Mandatory=$true, Position=2)]
        [ValidateSet("TCP", "UDP")]
        [string]
        $Protocol
        )

    $RemoteServer = If ([string]::IsNullOrEmpty($ComputerName)) {$IPAddress} Else {$ComputerName};

    If ($Protocol -eq 'TCP')
    {
        $test = New-Object System.Net.Sockets.TcpClient;
        Try
        {
            Write-Host "Connecting to "$RemoteServer":"$Port" (TCP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Host "Connection successful";
        }
        Catch
        {
            Write-Host "Connection failed";
        }
        Finally
        {
            $test.Dispose();
        }
    }

    If ($Protocol -eq 'UDP')
    {
   
        $test = New-Object System.Net.Sockets.UdpClient;
        Try
        {
            Write-Host "Connecting to "$RemoteServer":"$Port" (UDP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Host "Connection successful";
        }
        Catch
        {
            Write-Host "Connection failed";
        }
        Finally
        {
            $test.Dispose();
        }
        
    }
}

Function TestSSH
{

     Param($hosts_ip)
$checkping = Test-Connection $hosts_ip -Quiet

If ($checkping) 
    {

    TestPort -IPAddress $hosts_ip -Port 22 -Protocol TCP
    }
Else
    {
    Write-Host "Cannot ping host"
    }


} # End function TestSSH


Function TestRDP
{

     Param($VMs_ip)
$checkping = Test-Connection $VMs_ip -Quiet

If ($checkping) 
    {

    TestPort -IPAddress $VMs_ip -Port 3389 -Protocol TCP
    }
Else
    {
    Write-Host "Cannot ping VM"
    }


} # End function TestRDP



Function ListVMPowerState
{

    Param($hosts_ip)

Connect-VIServer -Server $hosts_ip -Protocol https -User root -Password P@ssw0rd

$vms_on = Get-Vm | where {$_.PowerState -eq "PoweredOn"}
$vms_off = Get-Vm | where {$_.PowerState -eq "PoweredOff"}

} # End function ListVMPowerState



## Execute

## Test RDP for VMs in PreQA

Connect-VIServer -Server 10.9.1.185 -Protocol https -User root -Password P@ssw0rd

Get-VM | Select Name, @{N="ip";E={@($_.guest.IPAddress[0])}} | Export-Csv vm_ip.csv 

Import-Csv vm_ip.csv |  
foreach {  
    $VMs = $_.ip  
      
    #Test RDP for each VM
    TestRDP $VMs 
}  











$checkping = Test-Connection 10.9.1.185 -Quiet
If ($checkping)
{
Connect-VIServer -Server 10.9.1.185 -Protocol https -User root -Password P@ssw0rd

##Check host
##Check PowerState
$hosts_powerstate = Get-VMHost | Select Name,PowerState
echo $hosts_powerstate

##Check SSH
$hosts_SSH = Get-VMHost | Get-VMHostService | where {$_.Key -eq 'TSM-SSH'} |
Select @{N='VMHost';E={$_.VMHost.Name}},Running
echo $hosts_SSH

#$hoststat = "" | Select HostName, MemMax, MemAvg, MemMin, CPUMax, CPUAvg, CPUMin
#$hoststat.HostName = $vmHost.name
#Get-VM |
#select Name, PowerState,
#   @{N='GuestOS';E={$_.ExtensionData.Guest.guestFullName}},
#    @{ Name="ToolsVersion"; Expression={$_.ExtensionData.config.tools.toolsVersion}},
#    @{ Name="ToolStatus"; Expression={$_.ExtensionData.Guest.ToolsVersionStatus}}

##Check VMs
$allvms = @()
$vms_on = Get-Vm | where {$_.PowerState -eq "PoweredOn"}
$vms_off = Get-Vm | where {$_.PowerState -eq "PoweredOff"}

##Khai bao function GetCPUMemInfo
	Function GetCPUMemInfo()
{
$stats = Get-Stat -Entity $vms_on -start (get-date).AddDays(-30) -Finish (Get-Date)-MaxSamples 10000 -stat "cpu.usage.average","mem.usage.average"  
$stats | Group-Object -Property Entity | %{
  $vmstat = "" | Select VmName, MemMax, MemAvg, MemMin, CPUMax, CPUAvg, CPUMin
  $vmstat.VmName = $_.name
 
  $cpu = $_.Group | where {$_.MetricId -eq "cpu.usage.average"} | Measure-Object -Property value -Average -Maximum -Minimum
  $mem = $_.Group | where {$_.MetricId -eq "mem.usage.average"} | Measure-Object -Property value -Average -Maximum -Minimum

  $vmstat.CPUMax = [int]$cpu.Maximum
  $vmstat.CPUAvg = [int]$cpu.Average
  $vmstat.CPUMin = [int]$cpu.Minimum
  $vmstat.MemMax = [int]$mem.Maximum
  $vmstat.MemAvg = [int]$mem.Average
  $vmstat.MemMin = [int]$mem.Minimum  
  $allvms += $vmstat
}
$allvms | Select VmName, MemMax, MemAvg, MemMin, CPUMax, CPUAvg, CPUMin | Export-Csv "c:\VMs.csv" -noTypeInformation
}

}
Else
{Write-Host "Cannot connect host"}

GetCPUMemInfo

##Khai bao function gui mail

Function SendEmail()
{
$secpasswd = ConvertTo-SecureString "password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("user1@behappy.local", $secpasswd)
Send-MailMessage -to t.vo@aswigsolutions.com -from MonitorScript -SmtpServer 10.9.0.22 -Subject Testmail -Credential $mycreds
}
