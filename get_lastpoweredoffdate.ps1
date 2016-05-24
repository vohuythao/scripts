﻿function Get-VMLastPoweredOffDate {
  param([Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl] $vm)
  process {
    $Report = "" | Select-Object -Property Name,LastPoweredOffDate,UserName
    $Report.Name = $vm.Name
    $Event = Get-VIEvent -Entity $vm -MaxSamples 10000 | `
      Where-Object { $_.GetType().Name -eq "VmPoweredOffEvent" } | `
      Sort-Object -Property CreatedTime -Descending | `
      Select-Object -First 1
    $Report.LastPoweredOffDate = $Event.CreatedTime
    $Report.UserName = $Event.UserName
    $Report
  }
}

function Get-VMLastPoweredOnDate {
  param([Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl] $vm)

  process {
    $Report = "" | Select-Object -Property Name,LastPoweredOnDate,UserName
    $Report.Name = $vm.Name
    $Event = Get-VIEvent -Entity $vm -MaxSamples 10000 | `
      Where-Object { $_.GetType().Name -eq "VmPoweredOnEvent" -or $_.GetType().Name -eq "DrsVmPoweredOnEvent"} | `
      Sort-Object -Property CreatedTime -Descending |`
      Select-Object -First 1
    $Report.LastPoweredOnDate = $Event.CreatedTime
    $Report.UserName = $Event.UserName
    $Report
  }
}

New-VIProperty -Name LastPoweredOffDate -ObjectType VirtualMachine -Value {(Get-VMLastPoweredOffDate -vm $Args[0]).LastPoweredOffDate} -Force
New-VIProperty -Name LastPoweredOffUserName -ObjectType VirtualMachine -Value {(Get-VMLastPoweredOffDate -vm $Args[0]).UserName} -Force
New-VIProperty -Name LastPoweredOnDate -ObjectType VirtualMachine -Value {(Get-VMLastPoweredOnDate -vm $Args[0]).LastPoweredOnDate} -Force
New-VIProperty -Name LastPoweredOnUserName -ObjectType VirtualMachine -Value {(Get-VMLastPoweredOnDate -vm $Args[0]).UserName} -Force

$VCServerName = Read-Host "What is the Virtual Center name?"

Connect-VIServer -Server $VCServerName

$OutArray = @()
$vms = @(Get-VM | Select-Object -property Name,LastPoweredOnDate,LastPoweredOnUserName,LastPoweredOffDate,LastPoweredOffUserName)

foreach ($vm in $vms) {
	$name = $vm.name
	$poweredOn = $vm.LastPoweredOnDate
	$poweredOnUser = $vm.LastPoweredOnUserName
	$poweredOff = $vm.LastPoweredOffDate
	$poweredOffUser = $vm.LastPoweredOffUserName
	
	$OutArray += New-Object PsCustomObject -Property @{ 
	'Name' = $name
	'Last Powered On Date' = $poweredOn
	'Last Powered On By' = $poweredOnUser
	'Last Powered Off Date' = $poweredOff
	'Last Powered Off By' = $poweredOffUser
	} | Select Name,"Last Powered On Date","Last Powered On By","Last Powered Off Date","Last Powered Off By"
}
$OutArray | Format-Table Name,"Last Powered On Date","Last Powered On By","Last Powered Off Date","Last Powered Off By"
$OutArray | Export-Csv ".\vmPowerReport.csv" -NoTypeInformation