﻿param( [string] $VIServer )

if ($VIServer -eq ""){
	Write-Host
	Write-Host "Please specify a VI Server name eg...."
	Write-Host "      powershell.exe Report.ps1 MYVISERVER"
	Write-Host
	Write-Host
	exit
}

function PreReq
{
	if ((Test-Path  REGISTRY::HKEY_CLASSES_ROOT\Word.Application) -eq $False){
		Write-Host "This script directly outputs to Microsoft Word, please install Microsoft Word"
		exit
	}
	Else
	{
		Write-Host "Microsoft Word Detected"
	}
	if ((Test-Path  REGISTRY::HKEY_CLASSES_ROOT\OWC11.ChartSpace.11) -eq $False){
		Write-Host "This script requires Office Web Components to run correctly, please install these from the following website: http://www.microsoft.com/downloads/details.aspx?FamilyId=7287252C-402E-4F72-97A5-E0FD290D4B76&displaylang=en"
		exit
	}
	Else
	{
		Write-Host "Office Web Components Detected"
	}
	$wordrunning = (Get-Process 'WinWord' -ea SilentlyContinue)
	if ( $wordrunning -eq ""){
		Write-Host "Please close all instances of Microsoft Word before running this report."
		exit
	}
	else
	{
	}
}

function InsertTitle ($title)
{
	# Insert Document Title Information
	$objSelection = $msWord.Selection
	$objSelection.Style = "Heading 1"
	$objSelection.TypeText($Title)
	$msword.Selection.EndKey(6)  > Null
	$objSelection.TypeParagraph()
	$msword.Selection.EndKey(6)  > Null
}

function InsertText ($text)
{
	# Insert Document text
	$objSelection = $msWord.Selection
	$objSelection.Style = "Normal"
	$objSelection.TypeText($text)
	$msword.Selection.EndKey(6)  > Null
	$objSelection.TypeParagraph()
	$msword.Selection.EndKey(6)  > Null
}

function InsertChart ($Caption, $Stat, $NumToReturn, $Contents)
{
	Write-Host "Creating $Caption bar chart...Please Wait"
	$categories = @()
	$values = @()
	$chart = new-object -com OWC11.ChartSpace.11
	$chart.Clear()
	$c = $chart.charts.Add(0)
	# 3D chart type, change the following .Type = 52
	$c.Type = 4
	$c.HasTitle = "True"
	$series = ([array] $chart.charts)[0].SeriesCollection.Add(0)

	if ($stat -eq ""){ 
	$contents | foreach-object {
		$categories += $_.Name
		$values += $_.Value * 1	
		}
	$series.Caption = $Caption 
	}
	else
	{
		$i = 1
		$j = $contents.Length
		$myCol = @()
		ForEach ($content in $contents)
		{
			Write-Progress -Activity "Processing Graph Information" -Status "$content ($i of $j)" -PercentComplete (100*$i/$j)
			$myObj = "" | Select-Object Name, Value
			$myObj.Name = $content.Name
			$messtat = Get-Stat -Entity $content -Start ((Get-Date).AddHours(-24)) -Finish (Get-Date) -Stat $stat
			$myObj.Value = ($messtat| Measure-Object -Property Value -Average).Average
			$myCol += $myObj
			$i++
		}
		$myCol | Sort-Object Value -Descending | Select-Object -First $numtoreturn | foreach-object {
			$categories += $_.Name
			$values += $_.Value * 1
		}
	$series.Caption = "$Caption (last 24hrs)"
	}
	$series.SetData(1, -1, $categories)
	$series.SetData(2, -1, $values)
	$filename = (resolve-path .).Path + "\Chart.jpg"
	$chart.ExportPicture($filename, "jpg", 900, 600)
	
	$objSelection = $msWord.Selection
	$msword.Selection.EndKey(6)  > Null
	$objSelection.TypeParagraph()
	$msWord.Application.Selection.InlineShapes.AddPicture($filename)  > Null
	Remove-Item $filename
	$msword.Selection.EndKey(6)  > Null
}

function InsertPie ($Caption, $Contents, $cats)
{
	Write-Host "Creating $Caption pie chart...Please Wait"
	$categories = @()
	$values = @()
	$chart = new-object -com OWC11.ChartSpace.11
	$chart.Clear()
	$c = $chart.charts.Add(0)
	# Non 3D pie chart, change the following .Type = 18
	$c.Type = 58
  	$c.HasTitle = "True"
	$c.HasLegend = "True"
	$series = ([array] $chart.charts)[0].SeriesCollection.Add(0)
	$dl =  $series.DataLabelsCollection.Add()
	$dl.HasValue = "True"
		
	$Contents | foreach-object { 
	$categories = $cats[0], $cats[1]
	$values = [math]::round(($contents[0]), 0), [math]::round(($contents[1]), 0)
	}
		
	$series.Caption = $Caption
	$series.SetData(1, -1, $categories)
	$series.SetData(2, -1, $values)
	$filename = (resolve-path .).Path + "\PIE.jpg"
	$chart.ExportPicture($filename, "jpg", 900, 600)
	
	$objSelection = $msWord.Selection
	$msword.Selection.EndKey(6) > Null
	$objSelection.TypeParagraph()
	$msWord.Application.Selection.InlineShapes.AddPicture($filename) > Null
	$msword.Selection.EndKey(6)  > Null
	Remove-Item $filename
}

function TableOutput ($Heading, $columnHeaders, $columnProperties, $contents)
{
	Write-Host "Creating $Heading Table...Please Wait"
	# Number of columns
	$columnCount = $columnHeaders.Count

	# Insert Table Heading
	$Title = $Heading
	InsertTitle $title

	# Create a new table
	$docTable = $wordDoc.Tables.Add($wordDoc.Application.Selection.Range,$contents.Count,$columnCount)

	# Insert the column headers into the table
	for ($col = 0; $col -lt $columnCount; $col++) {
    	$cell = $docTable.Cell(1,$col+1).Range
    	$cell.Font.Name="Arial"
    	$cell.Font.Bold=$true
    	$cell.InsertAfter($columnHeaders[$col])
	}
	$doctable.Rows.Add() > Null

	# Load the data into the table
	$i = 1
	$j = $contents.Count
	for($row = 2; $row -lt ($contents.Count + 2); $row++){
  		if($row -gt 2){
  	}
  	for ($col = 1; $col -le $columnCount; $col++){
		Write-Progress -Activity "Processing Table Information" -Status "Adding Row entry $i of $j" -PercentComplete (100*$i/$j)
    	$cell = $docTable.Cell($row,$col).Range
    	$cell.Font.Name="Arial"
    	$cell.Font.Size="10"
    	$cell.Font.Bold=$FALSE
    	$cell.Text = $contents[$row-2].($columnProperties[$col-1])
  	}
	$i++
	}

	# Table style
	$doctable.Style = "Table List 4"
	$docTable.Columns.AutoFit()
	$objSelection = $msWord.Selection
	$msword.Selection.EndKey(6)  > Null
	$objSelection.TypeParagraph()
	$msword.Selection.EndKey(6)  > Null

}
$date = Get-date
Prereq

# Connect to the VI Server
Write-Host "Connecting to VI Server"
Connect-VIServer $VIServer

# Get Word Ready for Input
# Launch instance of Microsoft Word
Write-Host "Creating New Word Document"
$msWord = New-Object -Com Word.Application
# Create new document
$wordDoc = $msWord.Documents.Add()
# Make word visible (optional)
$msWord.Visible = $false
# Activate the new document
$wordDoc.Activate()

# Insert Document Title

$Title = "VMWare Report produced for $VIServer"
InsertTitle $title

$Title = "Created on " + $date
InsertTitle $title

#Setting common used commands to speed things up
Write-Host "Setting Variables...Please wait"
$VMs = Get-VM
$VMHs = Get-VMHost
$Ds = Get-Datastore
$rp = Get-resourcepool
$clu = Get-Cluster

# Send VM Host Information to Document
$myCol = @()
ForEach ($vmh in $vmhs)
{
  $hosts = Get-VMHost $vmh.Name | %{Get-View $_.ID}
  $esx = "" | select-Object Name, Version, NumCpuPackages, NumCpuCores, Hz, Memory
  $esx.Name = $hosts.Name
  $esx.Version = $hosts.Summary.Config.Product.FullName
  $esx.NumCpuPackages = $hosts.Hardware.CpuInfo.NumCpuPackages 
  $esx.NumCpuCores = $hosts.Hardware.CpuInfo.NumCpuCores
  $esx.Hz = [math]::round(($hosts.Hardware.CpuInfo.Hz)/10000, 0)
  $esx.Memory = [math]::round(($hosts.Hardware.MemorySize)/1024, 0)
  $myCol += $esx
}
$contents = $myCol
$columnHeaders = @('Name', 'Version', 'CPU', 'Cores', 'Hz', 'Memory' )
$columnproperties = @('Name', 'Version', 'NumCpuPackages', 'NumCpuCores', 'Hz', 'Memory')
$Heading = "Host Information"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	Tableoutput $Heading $columnHeaders $columnProperties $contents
}

$totalhosts = $VMhs.Length
$Text = "Total Number of Hosts: $totalhosts"
InsertText $Text

#Insert VM Host CPU Graph
$contents = $VMHs
$Stat = "cpu.usage.average"
$NumToReturn = 5
$Caption = "Top " + $NumToReturn + " Hosts CPU Usage %Average"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	InsertChart $Caption $Stat $NumToReturn $contents
}

#Insert VM Host MEM Graph
$contents = $VMHs
$Stat = "mem.usage.average"
$NumToReturn = 5
$Caption = "Top " + $NumToReturn + " Hosts MEM Usage %Average"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	InsertChart $Caption $Stat $NumToReturn $contents
}

# Send VM Information to the document
$contents = @($VMs | Sort-Object Name )
$columnHeaders = @('Name','CPUs','MEM','Power','Description')
$columnProperties = @('Name','NumCPU','MemoryMB','PowerState','Description')
$Heading = "VM Information"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	Tableoutput $Heading $columnHeaders $columnProperties $contents
}

$totalhosts = $VMs.Length
$Text = "Total Number of Virtual Machines: $totalhosts"
InsertText $Text

#Insert VM CPU Graph
$contents = $VMs
$Stat = "cpu.usage.average"
$NumToReturn = 5
$Caption = "Top " + $NumToReturn + " Virtual Machines CPU Usage %Average"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	InsertChart $Caption $Stat $NumToReturn $contents
}

#Insert VM MEM Graph
$contents = $VMs
$Stat = "mem.usage.average"
$NumToReturn = 5
$Caption = "Top " + $NumToReturn + " Virtual Machines MEM Usage %Average"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	InsertChart $Caption $Stat $NumToReturn $contents
}

# Send VM Tools Information to Document
$contents = @($VMs | % { get-view $_.ID } | select Name, @{ Name="ToolsVersion"; Expression={$_.config.tools.toolsVersion}} | Sort-Object Name)
$columnHeaders = @('Name','VM Tools Version')
$columnproperties = @('Name', 'ToolsVersion')
$Heading = "VMWare Tools Version"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	Tableoutput $Heading $columnHeaders $columnProperties $contents
}

# Datastore report
$contents = @($Ds | Sort-Object Name)
$columnHeaders = @('Name','Storage Type','Total Size','Free Space')
$columnProperties = @('Name','Type','CapacityMB','FreeSpaceMB')
$Heading = "Datastore Information"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	Tableoutput $Heading $columnHeaders $columnProperties $contents
}

#Insert Datastore Pie Charts
foreach ($contents in $Ds)
{
$UsedSpace = $contents.CapacityMB - $contents.FreespaceMB
$categories = @('Free Space', 'Used Space')
$newcontents = @($contents.FreespaceMB, $usedSpace)
$Caption = $contents.Name + " Space Allocation"
if ($contents -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	InsertPie $Caption $newcontents $categories
}

} 

# Send Cluster Information to Document
$contents = @($clu | Sort-Object Name)
$columnHeaders = @('Name','HA Enabled','HA Failover Level','DRS Enabled','DRS Mode')
$columnProperties = @('Name', 'HAEnabled', 'HAFailoverLevel', 'DRSEnabled', 'DrsMode')
$Heading = "Cluster Information"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	Tableoutput $Heading $columnHeaders $columnProperties $contents
}

# Send ResourcePool Information to Document
$contents = @($rp | select-object Name, MemLimitMB, CpuLimitMhz, NumCPUShares, NumMemShares | Sort-Object Name)
$columnHeaders = @('Name', 'Memory Limit MB', 'CPU Limit Mhz', 'CPU Shares', 'MEM Shares')
$columnProperties = @('Name', 'MemLimitMB', 'CpuLimitMhz', 'NumCPUShares', 'NumMemShares')
$Heading = "Resource Pool Information"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	Tableoutput $Heading $columnHeaders $columnProperties $contents
}

# Send Snapshot Information to Document
$contents = @($VMs | Get-Snapshot | select-object VM, Name, Description)
$columnHeaders = @('VM', 'Name', 'Description')
$columnProperties = @('VM', 'Name', 'Description')
$Heading = "Snapshot Information"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	Tableoutput $Heading $columnHeaders $columnProperties $contents
}

# Send Snapshot's over 1 month old to Document
$contents = @($VMs | Get-Snapshot | where { $_.Created -lt (get-date).addmonths(-1)} | select-object VM, Name, Description, Created)
$columnHeaders = @('VM', 'Name', 'Description', 'Created')
$columnProperties = @('VM', 'Name', 'Description', 'Created')
$Heading = "Snapshot's over 1 Month old"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	Tableoutput $Heading $columnHeaders $columnProperties $contents
}

#Insert Snapshot Graph
$myCol = @()
ForEach ($vm in $vms)
{
  $snapshots = Get-Snapshot -VM $vm
  $myObj = "" | Select-Object Name, Value
  $myObj.Name = $vm.name
  $myObj.Value = ($snapshots | measure-object).count
  $myCol += $myObj
}
$contents = @($myCol | Where-Object{$_.Value -gt 0} |  Sort-Object Name)
$Stat = ""
$NumToReturn = ""
$Caption = "Number of snapshots per VM"
if ($contents[0] -eq $null){
	Write-Host "No entries for $Heading found"
}
else
{
	InsertChart $Caption $Stat $NumToReturn $contents
}

Write-Host "------------------------------"
Write-Host "Start Date: $date"
$enddate = get-date
Write-Host "End Date:   $enddate"

# Show the finished Report
$msword.Selection.HomeKey(6)  > Null
$msWord.Visible = $true

# Save the document to disk and close it
$filename = 'C:\VMReport.doc'
$wordDoc.SaveAs([ref]$filename)

#Close the document if you are using as a scheduled task
#$wordDoc.Close()

# Exit our instance of word
#$msWord.Application.Quit()

#Email options for automated emailed report
#$smtpServer = “localhost”
#
#$msg = new-object Net.Mail.MailMessage
#$att = new-object Net.Mail.Attachment($filename)
#$smtp = new-object Net.Mail.SmtpClient($smtpServer)
#
#$msg.From = “somebody@yourdomain.com”
#$msg.To.Add(”somebody@theirdomain.com”)
#$msg.Subject = “VMware Report”
#$msg.Body = “Please find attached the automated VMware report”
#$msg.Attachments.Add($att)
#
#$smtp.Send($msg)

#Delete file if no longer needed once sent via email
#Remove-Item $filename
Disconnect-VIServer -Confirm:$False
