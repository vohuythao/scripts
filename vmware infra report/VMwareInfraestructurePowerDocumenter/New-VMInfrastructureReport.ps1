##
## VMware Infraestructure Power Documenter
## Author: Antonio Zamora
## Company: StaffDotNet
## Email: antonio.zamora@staffdotnet.com
## Blog: http://blogs.staffdotnet.com/antoniozamora
##
##################

param
(
	$fileName			= $(throw "Specify the file name"),
	$outputPath			= "./",
	$outputType			= $(throw "Specify the output type (spreadsheetml or wordprocessingml)"),
	$reportType			= $(throw "Specify the report type. For Wml: vm, stats. events, vmevents, tasks, inventory. For sml: vm, tasks, stats"),
	$spreadsheetStyleTemplate 	= "spreadsheetmlStyleTemplate.xlsx",
	$wordStyleTemplate	 	= "wordprocessingmlStyleTemplate.docx",
	[switch]$chart			= $false, #indicates if an excel chart will be created
	$chartType 			= 'bar', #they could be: bar, pie, column, line
	$chartXColumns,			# values showed on the X columns (you can put as many as you want separated by coma)
	$chartYColumn,			# values showed on the Y columns (you can put as many as you want separated by coma)
	$filterColumn,			# this is the right side of a where $_ -eq xx. Place de names of the properties you want to filter ...
	$filterValue 			= "", # ... by this value
	$company			= "Put Here Your Company Name",
	$serverIp			= $(throw "Specify the server ip"), # ESX server IP
	$user				= $(throw "Specify the user name"),
	$password			= $(throw "Specify the user password")
)


# build a paragraphs using sompe openxml
function paragraph([string]$sentence)
{
	return "<w:p>" + $sentence + "</w:p>"
}


# build a sentence using sompe openxml
function sentence([string]$text, [string]$style, [int]$tabsNumber)
{
	$tabs = ""
	while($tabsNumber -gt 0)
	{
		$tabs = $tabs + "<w:tab />"
		$tabsNumber = $tabsNumber - 1
	}
	return "<w:r><w:rPr><w:rStyle w:val=""" + $style + """ /></w:rPr>"+ $tabs +"<w:t xml:space=""preserve"">" + $text  + "</w:t></w:r>"
}


# this just builds the firs page openxml placing the titles
function firstPage([string]$company, [string]$title)
{
	$actualDate = date
	$actualDay = $actualDate.Day
	$actualMonth = $actualDate.Month
	$actualYear = $actualDate.Year
	return "<w:p/><w:p/><w:p/><w:p/><w:p/><w:p><w:pPr><w:pStyle w:val=""vmwareheading1"" /><w:jc w:val=""right"" /><w:rPr><w:b /></w:rPr></w:pPr><w:r><w:rPr><w:b /></w:rPr><w:t>	Company $company</w:t></w:r></w:p><w:p><w:pPr><w:pStyle w:val=""vmwareheading1"" /><w:jc w:val=""right"" /><w:rPr><w:b /></w:rPr></w:pPr><w:r><w:rPr><w:b /></w:rPr><w:t>$title</w:t></w:r></w:p><w:p><w:pPr><w:pStyle w:val=""vmwareheading1"" /><w:jc w:val=""right"" /><w:rPr><w:b /></w:rPr></w:pPr><w:r><w:rPr><w:b /></w:rPr><w:t>Server: $server</w:t></w:r></w:p><w:p><w:pPr><w:pStyle w:val=""vmwareheading1"" /><w:jc w:val=""right"" /><w:rPr><w:b /></w:rPr></w:pPr><w:r><w:rPr><w:b /></w:rPr><w:t>$actualDay - $actualMonth - $actualYear</w:t></w:r></w:p><w:p><w:pPr><w:jc w:val=""right"" /><w:rPr><w:b /><w:lang w:val=""es-CR"" /></w:rPr></w:pPr><w:r><w:rPr><w:b /><w:lang w:val=""es-CR"" /></w:rPr></w:r></w:p>" + "<w:p><w:pPr><w:rPr><w:lang w:val=""esCR"" /></w:rPr></w:pPr><w:r><w:rPr><w:lang w:val=""esCR"" /></w:rPr><w:br w:type=""page"" /></w:r></w:p>"
}


#first of all check if the powertools and the vmware toolkit exist
$vmwaretoolkit = Get-PSSnapin | where {$_.Name -eq "VMware.VimAutomation.Core"}
$openxmlpowertools = Get-PSSnapin | where {$_.Name -eq "OpenXml.PowerTools"}


if($vmwaretoolkit -and $openxmlpowertools)
{
	$server = Connect-VIServer -Server $serverIp -Protocol https -User $user -Password $password

	# check if the document is an wordprocessingml or spreadsheetml document
	if($outputType -eq "wordprocessingml")
	{
		echo "A wordprocessing document will be created."

		$documentPath = $outputPath + $fileName

		# create the document. Build a new one with only a space inside it
		Export-OpenXmlWordprocessing -OutputPath $documentPath -Text " "

		##creating the document

		switch ($reportType)
		{
			"vm"		
			{
				#build the title
				$content = firstPage $company "Virtual Machines Inventory"

				ForEach($vm in Get-VM)
				{
					$content = $content + (paragraph ((sentence "Virtual Machine: " "vmwareheading2Char")  + (sentence $vm.Name "vmwarestrongChar")))
					$content = $content + (paragraph ((sentence "Host: " "vmwarestrongChar")  + (sentence $vm.Host.Name "normal")))
					$content = $content + (paragraph ((sentence "Memory: " "vmwarestrongChar")  + (sentence $vm.MemoryMB "normal")))
					$content = $content + (paragraph ((sentence "Number of Cpu: " "vmwarestrongChar")  + (sentence $vm.NumCpu "normal")))
					$content = $content + (paragraph ((sentence "Power State: " "vmwarestrongChar")  + (sentence $vm.PowerState "normal")))

					#Guest info
					$guest = $vm.Guest
					$content = $content + (paragraph (sentence "-- Guest  --" "vmwarecolumntitleChar"))
					$content = $content + (paragraph ((sentence "OS Name: " "vmwarestrongChar" 1)  + (sentence $guest.OSFullName "normal")))
					$content = $content + (paragraph ((sentence "IP Address: " "vmwarestrongChar" 1)  + (sentence $guest.IPAddress "normal")))
					$content = $content + (paragraph ((sentence "State: " "vmwarestrongChar" 1)  + (sentence $guest.State "normal")))
					$content = $content + (paragraph ((sentence "Screen Dimension: " "vmwarestrongChar" 1)  + (sentence $guest.ScreenDimensions "normal")))

					#hard disks
					$content = $content + (paragraph (sentence "Hard Disks: " "vmwarestrongChar"))
					foreach($hd in $vm.HardDisks)
					{
						$content = $content + (paragraph (sentence ("--  " + $hd.Name + "  --") "vmwarecolumntitleChar"))
						$content = $content + (paragraph ((sentence "Capacity in KB: " "vmwarestrongChar" 1)  + (sentence $hd.CapacityKB "normal")))
						$content = $content + (paragraph ((sentence "Disk Type: " "vmwarestrongChar" 1)  + (sentence $hd.Disktype "normal")))
					}

				}
			}
			"vmstats"
			{
				$content = firstPage $company "Server Status"

				ForEach($vm in Get-VM)
				{
					$content = $content + (paragraph ((sentence "Virtual Machine: " "vmwareheading2Char")  + (sentence $vm.Name "vmwarestrongChar")))

					#disk stats
					$content = $content + (paragraph (sentence "Disk status" "vmwarestrongChar"))
					$content = $content + (paragraph ((sentence "Metric" "vmwarecolumntitleChar") + (sentence "Time" "vmwarecolumntitleChar" 4) + (sentence "Value" "vmwarecolumntitleChar" 4) + (sentence "Unit" "vmwarecolumntitleChar" 2)))
					foreach($Metric in (Get-Stat -Entity $vm,$vm.Host -Disk))
					{
						$content = $content + (paragraph ((sentence $Metric.MetricId "normal") + (sentence ($Metric.Timestamp.ToShortDateString() + " " + $Metric.Timestamp.ToShortTimeString()) "normal" 2) + (sentence $Metric.Value "normal" 2) + (sentence $Metric.Unit "normal" 2)) )
					}

					#Memory stats
					$content = $content + (paragraph (sentence "Memory status" "vmwarestrongChar"))
					$content = $content + (paragraph ((sentence "Metric" "vmwarecolumntitleChar") + (sentence "Time" "vmwarecolumntitleChar" 4) + (sentence "Value" "vmwarecolumntitleChar" 4) + (sentence "Unit" "vmwarecolumntitleChar" 2)))
					foreach($Metric in (Get-Stat -Entity $vm,$vm.Host -Memory))
					{
						$content = $content + (paragraph ((sentence $Metric.MetricId "normal") + (sentence ($Metric.Timestamp.ToShortDateString() + " " + $Metric.Timestamp.ToShortTimeString()) "normal" 2) + (sentence $Metric.Value "normal" 2) + (sentence $Metric.Unit "normal" 2)) )
					}

					#Cpu stats
					$content = $content + (paragraph (sentence "Cpu status" "vmwarestrongChar"))
					$content = $content + (paragraph ((sentence "Metric" "vmwarecolumntitleChar") + (sentence "Time" "vmwarecolumntitleChar" 4) + (sentence "Value" "vmwarecolumntitleChar" 4) + (sentence "Unit" "vmwarecolumntitleChar" 2)))
					foreach($Metric in (Get-Stat -Entity $vm,$vm.Host -Cpu))
					{
						$content = $content + (paragraph ((sentence $Metric.MetricId "normal") + (sentence ($Metric.Timestamp.ToShortDateString() + " " + $Metric.Timestamp.ToShortTimeString()) "normal" 2) + (sentence $Metric.Value "normal" 2) + (sentence $Metric.Unit "normal" 2)) )
					}

					#Network stats
					$content = $content + (paragraph (sentence "Network status" "vmwarestrongChar"))
					$content = $content + (paragraph ((sentence "Metric" "vmwarecolumntitleChar") + (sentence "Time" "vmwarecolumntitleChar" 4) + (sentence "Value" "vmwarecolumntitleChar" 4) + (sentence "Unit" "vmwarecolumntitleChar" 2)))
					foreach($Metric in (Get-Stat -Entity $vm,$vm.Host -Network))
					{
						$content = $content + (paragraph ((sentence $Metric.MetricId "normal") + (sentence ($Metric.Timestamp.ToShortDateString() + " " + $Metric.Timestamp.ToShortTimeString()) "normal" 2) + (sentence $Metric.Value "normal" 2) + (sentence $Metric.Unit "normal" 2)) )
					}
				}
			}
			"serverevents"
			{
				$content = firstPage $company "Server events"

				ForEach($viEvent in Get-VIEvent)
				{
					$content = $content + (paragraph (sentence ("-------------" + $viEvent.createdTime + "-------------") "vmwarecolumntitleChar"))
					$content = $content + (paragraph ((sentence "Ip Address: " "vmwarestrongChar")  + (sentence $viEvent.ipAddress "normal")))
					$content = $content + (paragraph ((sentence "User Name: " "vmwarestrongChar")  + (sentence $viEvent.userName "normal")))
					$content = $content + (paragraph ((sentence "Host Name: " "vmwarestrongChar")  + (sentence $viEvent.host.name "normal")))
					$content = $content + (paragraph ((sentence "Message: " "vmwarestrongChar")  + (sentence $viEvent.fullFormattedMessage "normal")))
				}
			}
			"vmevents"
			{
				$content = firstPage $company "Virtual Machine events"

				ForEach($vm in Get-VM)
				{
					$content = $content + (paragraph ((sentence "Virtual Machine: " "vmwareheading2Char")  + (sentence $vm.Name "vmwarestrongChar")))

					ForEach($viEvent in (Get-VIEvent -Entity $vm,$vm.Host))
					{
						$content = $content + (paragraph (sentence ("-------------" + $viEvent.createdTime + "-------------") "vmwarecolumntitleChar"))
						$content = $content + (paragraph ((sentence "Ip Address: " "vmwarestrongChar")  + (sentence $viEvent.ipAddress "normal")))
						$content = $content + (paragraph ((sentence "User Name: " "vmwarestrongChar")  + (sentence $viEvent.userName "normal")))
						$content = $content + (paragraph ((sentence "Host Name: " "vmwarestrongChar")  + (sentence $viEvent.host.name "normal")))
						$content = $content + (paragraph ((sentence "Message: " "vmwarestrongChar")  + (sentence $viEvent.fullFormattedMessage "normal")))
					}
				}


			}
			"servertasks"	
			{
				$content = firstPage $company "Server tasks"
				$content = $content + (paragraph ((sentence "Name" "vmwarecolumntitleChar") + (sentence "State" "vmwarecolumntitleChar" 3) + (sentence "% Complete" "vmwarecolumntitleChar" 2) + (sentence "Start Time" "vmwarecolumntitleChar" 1) + (sentence "Finish Time" "vmwarecolumntitleChar" 1)))
				ForEach($task in Get-Task)
				{
					$StartTime = ""
					$FinishTime = ""
					if($task.StartTime)
					{
						$StartTime = $task.StartTime.ToShortTimeString()
					}
					
					if($task.FinishTime)
					{
						$FinishTime = $task.FinishTime.ToShortTimeString() 
					}

					$content = $content + (paragraph ((sentence $task.Name "normal") + (sentence $task.State  "normal" 1) + (sentence $task.PercentComplete "normal" 2) + (sentence $StartTime "normal" 2) + (sentence $FinishTime "normal" 1)))
				}
			}
			"inventory"
			{
			
				#use a PSDrive with the VIMProvider to traverse the inventory.
			
				$content = firstPage $company "Datacenter Inventory Report"

				$root = Get-Folder -NoRecursion
				New-PSDrive -Location $root -Name vm -PSProvider VimInventory -Root '\'
				cd vm:
				[object[]]$actualFolder = ls # retrieve all the folder information and process it in a list
				foreach($datacenter in $actualFolder)
				{
				
					#while you do all this ... build the document with all the information you get from the provider
				
					$content = $content + (paragraph ((sentence "Datacenter: " "vmwareheading2Char")  + (sentence $datacenter.Name "vmwareheading2Char")))
					$datastore = Get-Datastore -Datacenter $datacenter
					$content = $content + (paragraph ((sentence "DataStore: " "vmwareheading2Char" 1)  + (sentence $datastore.Name "vmwarestrongChar")))
					$content = $content + (paragraph ((sentence "Type: " "vmwarestrongChar" 1)  + (sentence $datastore.Type "normal" 1)))
					$content = $content + (paragraph ((sentence "Capacity in MB: " "vmwarestrongChar" 1)  + (sentence $datastore.CapacityMB "normal" 1)))
					$content = $content + (paragraph ((sentence "Free space in MB: " "vmwarestrongChar" 1)  + (sentence $datastore.FreeSpaceMB "normal" 1)))

					cd $datacenter.Name
					cd host
					[object[]]$actualFolder = ls
					foreach($hostObject in $actualFolder)
					{
						$content = $content + (paragraph ((sentence "Host Server: " "vmwareheading2Char" 1)  + (sentence $hostObject.Name "vmwarestrongChar")))
						$content = $content + (paragraph ((sentence "State: " "vmwarestrongChar" 2)  + (sentence $hostObject.State "normal" 1)))
						cd $hostObject.name
						cd Resources
						[object[]]$actualFolder = ls
						$content = $content + (paragraph (sentence "Resource Pools " "vmwareheading2Char" 2))
						foreach($Resource in $actualFolder)
						{
							$content = $content + (paragraph ((sentence ("--  " + $Resource.Name + "  --") "vmwarestrongChar" 2)))

							$content = $content + (paragraph ((sentence "CpuSharesLevel: " "vmwarestrongChar" 3)  + (sentence $Resource.CpuSharesLevel "normal" 3)))

							$content = $content + (paragraph ((sentence "CpuReservationMHz: " "vmwarestrongChar" 3)  + (sentence $Resource.CpuReservationMHz "normal" 3)))

							$content = $content + (paragraph ((sentence "CpuExpandableReservation: " "vmwarestrongChar" 3)  + (sentence $Resource.CpuExpandableReservation "normal" 2)))

							$content = $content + (paragraph ((sentence "CpuLimitMHz: " "vmwarestrongChar" 3)  + (sentence $Resource.CpuLimitMHz "normal" 3)))

							$content = $content + (paragraph ((sentence "MemSharesLevel: " "vmwarestrongChar" 3)  + (sentence $Resource.MemSharesLevel "normal" 3)))

							$content = $content + (paragraph ((sentence "NumMemShares: " "vmwarestrongChar" 3)  + (sentence $Resource.NumMemShares "normal" 3)))

							$content = $content + (paragraph ((sentence "MemReservationMB: " "vmwarestrongChar" 3)  + (sentence $Resource.MemReservationMB "normal" 2)))

							$content = $content + (paragraph ((sentence "MemExpandableReservation: " "vmwarestrongChar" 3)  + (sentence $Resource.MemExpandableReservation "normal" 1)))

							$content = $content + (paragraph ((sentence "MemLimitMB: " "vmwarestrongChar" 3)  + (sentence $Resource.MemLimitMB "normal" 3)))						

							cd $Resource.name
							[object[]]$actualFolder = ls
							$content = $content + (paragraph ((sentence "Virtual Machines: " "vmwarestrongChar" 3)))
							foreach($vm in $actualFolder)
							{
								$content = $content + (paragraph (sentence $vm.Name "normal" 4))
							}
							cd ..
						}
						cd ..
						cd ..
					}
					cd ..
					cd ..
				}
				# Return to your normal folder
				cd c:
				Remove-PSDrive -Name vm
			}
		}

		# Add all the content in the created document. then, retrieve the style from the styles document. This will retrieve the styles.xml file containing our template styles			

		Add-OpenXmlContent -InsertionPoint /w:document/w:body -PartPath "/word/document.xml" -content $content -Path $documentPath -SuppressBackups
		Get-OpenXmlStyle -Path $wordStyleTemplate | Set-OpenXmlStyle -Path $documentPath -SuppressBackups
	}
	
	if($outputType -eq "spreadsheetml")
	{
		echo "A spreadsheet document will be created."
		$documentPath = $outputPath + $fileName
		switch ($reportType)
		{
			"vm"
			{
				[object[]]$vmList = ""
				if($FilterColumn -and $FilterValue)
				{
					$vmList = Get-VM | where { $_.$FilterColumn -eq $FilterValue } | select-object Name,PowerState,NumCpu,MemoryMB,Description,Host
				}
				else
				{
					$vmList = Get-VM | select-object Name,PowerState,NumCpu,MemoryMB,Description,Host
				}

				if($vmlist)
				{
					$vmList | Export-OpenXmlSpreadsheet -OutputPath $documentPath -InitialRow 7 -SuppressBackups
					Add-OpenXmlSpreadSheetTable -Path $documentPath -tableStyle TableStyleLight9 -useHeaders yes -fromColumn 1 -toColumn 6 -fromRow 7 -toRow ($vmList.count + 7)  -WorksheetName sheet -SuppressBackups
					Get-OpenXmlStyle -Path $spreadsheetStyleTemplate | Set-OpenXmlStyle -Path $documentPath -SuppressBackups
					
					Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 2 -col 1 -Value "Virtual Machines Inventory" -SuppressBackups
					Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 3 -col 1 -Value  "Company: $Company" -SuppressBackups
					Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 4 -col 1 -Value  (Get-date) -SuppressBackups
					Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 5 -col 1 -Value  "Server: $Server" -SuppressBackups
					
					Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 2 -col 1 -CellStyle "vmwareheading1" -SuppressBackups
					Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 3 -col 1 -CellStyle "vmwareheading2" -SuppressBackups
					Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 4 -col 1 -CellStyle "vmwareheading2" -SuppressBackups
					Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 5 -col 1 -CellStyle "vmwareheading2" -SuppressBackups
					
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 1 -ToColumn 1 -width 32 -SuppressBackups
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 2 -ToColumn 2 -width 15 -SuppressBackups
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 3 -ToColumn 3 -width 12 -SuppressBackups
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 4 -ToColumn 4 -width 15 -SuppressBackups
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 5 -ToColumn 5 -width 15 -SuppressBackups
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 6 -ToColumn 6 -width 34 -SuppressBackups
				}
				else
				{
					echo "There are no virtual machines to report. The document will not be created"
				}
			}
			"vmstats"
			{
				[object[]]$statusList = ""

				ForEach($vm in Get-VM)
				{
					$documentPath = ($outputPath + $vm.name + $fileName)
					
					if($FilterColumn -and $FilterValue)
					{
						$statusList = Get-Stat $vm,$vm.Host -Cpu -Memory -Disk -Network | where { $_.$FilterColumn -eq "$FilterValue" } | select-object TimeStamp,MetricId,Value,Unit,Description,Entity
					}
					else
					{
						$statusList = Get-Stat $vm,$vm.Host -Cpu -Memory -Disk -Network | select-object TimeStamp,MetricId,Value,Unit,Description,Entity
					}

					if($statusList)
					{

						if($chart)
						{
							if($chartXColumns -and $chartYColumn)
							{
								$statusList | Export-OpenXmlSpreadsheet -OutputPath $documentPath -chart -ChartType $chartType -ColumnsToChart $chartXColumns -HeaderColumn $chartYColumn -InitialRow 8 -SuppressBackups
							}
						}
						else
						{
							$statusList | Export-OpenXmlSpreadsheet -OutputPath $documentPath -InitialRow 8 -SuppressBackups
						}

						# create a filter table surrounding the spreadsheet information
						Add-OpenXmlSpreadSheetTable -Path $documentPath -tableStyle TableStyleLight9 -useHeaders yes -fromColumn 1 -toColumn 6 -fromRow 8 -toRow ($statusList.count + 8) -WorksheetName sheet -SuppressBackups
						
						# get and set the styles.xml containing styling information
						Get-OpenXmlStyle -Path $spreadsheetStyleTemplate | Set-OpenXmlStyle -Path $documentPath -SuppressBackups
						
						# Set the values of each cell inside our documents. Place informative headers for each document
						Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 2 -col 1 -Value "Virtual Machine Statistics" -SuppressBackups
						Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 3 -col 1 -Value  "Company: $Company" -SuppressBackups
						Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 4 -col 1 -Value  (Get-date) -SuppressBackups
						Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 5 -col 1 -Value  "Server: $Server" -SuppressBackups
						Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 6 -col 1 -Value  ("Virtual Machine: " + $vm.Name) -SuppressBackups

						# once the values are set it. set an style on them
						Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 2 -col 1 -CellStyle "vmwareheading1" -SuppressBackups
						Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 3 -col 1 -CellStyle "vmwareheading2" -SuppressBackups
						Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 4 -col 1 -CellStyle "vmwareheading2" -SuppressBackups
						Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 5 -col 1 -CellStyle "vmwareheading2" -SuppressBackups
						Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 6 -col 1 -CellStyle "vmwareheading2" -SuppressBackups

						# finally set the column width of each one of the spreadsheet document columns
						Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 1 -ToColumn 1 -width 32 -SuppressBackups
						Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 2 -ToColumn 2 -width 15 -SuppressBackups
						Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 3 -ToColumn 3 -width 12 -SuppressBackups
						Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 4 -ToColumn 4 -width 15 -SuppressBackups
						Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 5 -ToColumn 5 -width 15 -SuppressBackups
						Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 6 -ToColumn 6 -width 34 -SuppressBackups
					}
					else
					{
						echo "There is no status to report. The document will not be created"
					}
				}
			}
			"servertasks"	
			{
				[object[]] $taskList = ""
				if($FilterColumn -and $FilterValue)
				{
					$taskList = Get-Task | where { $_.$FilterColumn -eq "$FilterValue" } | select-object ObjectId,Name,StartTime,FinishTime,PercentComplete,State,Description,Result
				}
				else
				{
					$taskList = Get-Task | select-object ObjectId,Name,StartTime,FinishTime,PercentComplete,State,Description,Result
				}

				if($taskList)
				{
					
					$taskList | Export-OpenXmlSpreadsheet -OutputPath $documentPath -InitialRow 7 -SuppressBackups
					
					Add-OpenXmlSpreadSheetTable -Path $documentPath -tableStyle TableStyleLight9 -useHeaders yes -fromColumn 1 -toColumn 8 -fromRow 7 -toRow ($taskList.count + 7) -WorksheetName sheet -SuppressBackups
					Get-OpenXmlStyle -Path $spreadsheetStyleTemplate | Set-OpenXmlStyle -Path $documentPath -SuppressBackups

					Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 2 -col 1 -Value "Server tasks" -SuppressBackups
					Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 3 -col 1 -Value  "Company: $Company" -SuppressBackups
					Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 4 -col 1 -Value  (Get-date) -SuppressBackups
					Set-OpenXmlSpreadSheetCellValue -Path $documentPath -WorksheetName sheet -Row 5 -col 1 -Value  "Server: $Server" -SuppressBackups

					Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 2 -col 1 -CellStyle "vmwareheading1" -SuppressBackups
					Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 3 -col 1 -CellStyle "vmwareheading2" -SuppressBackups
					Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 4 -col 1 -CellStyle "vmwareheading2" -SuppressBackups
					Set-OpenXmlSpreadSheetCellStyle -Path $documentPath -WorksheetName sheet -Row 5 -col 1 -CellStyle "vmwareheading2" -SuppressBackups

					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 1 -ToColumn 1 -width 32 -SuppressBackups
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 2 -ToColumn 2 -width 15 -SuppressBackups
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 3 -ToColumn 3 -width 12 -SuppressBackups
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 4 -ToColumn 4 -width 15 -SuppressBackups
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 5 -ToColumn 5 -width 15 -SuppressBackups
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 6 -ToColumn 6 -width 34 -SuppressBackups
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 7 -ToColumn 7 -width 15 -SuppressBackups					
					Set-OpenXmlSpreadSheetColumnWidth -Path $documentPath -WorksheetName sheet -FromColumn 8 -ToColumn 8 -width 15 -SuppressBackups					
				}
				else
				{
					echo "There are no tasks to report. The document will not be created"
				}
			}
		}		
	}
}
else
{
	echo "Sorry. To run this script you need the have installed the vmware toolkit and the OpenXmlPowerTools"
}