#### Variables ####

$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace(0xA)
$temp = get-ChildItem "env:TEMP"
$temp2 = $temp.Value
$swtools = "c:SWTOOLS*"
$WinTemp = "c:WindowsTemp*"

#1# Remove temp files located in "C:UsersUSERNAMEAppDataLocalTemp"
write-Host "Removing Junk files in $temp2." -ForegroundColor Magenta 
Remove-Item -Recurse "$temp2*" -Force -Verbose

#2# Remove Item in c:Swtools folder excluding Checkpoint,landesk,useradmin folder ... remove -what if it if you want to do it ..
# write-Host "Emptying $swtools folder." 
#Remove-Item -Recurse $swtools -Verbose -Force -WhatIfEmpty 

#3# Empty Recycle Bin # http://demonictalkingskull.com/2010/06/empty-users-recycle-bin-with-powershell-and-gpo/
write-Host "Emptying Recycle Bin." -ForegroundColor Cyan 
$objFolder.items() | %{ remove-item $_.path -Recurse -Confirm:$false}

#4# Remove Windows Temp Directory 
write-Host "Removing Junk files in $WinTemp." -ForegroundColor Green
Remove-Item -Recurse $WinTemp -Force 

#5# Running Disk Clean up Tool 
write-Host "Finally now , Running Windows disk Clean up Tool" -ForegroundColor Cyan
cleanmgr /sagerun:1 | out-Null 

$([char]7)
Sleep 1 
$([char]7)
Sleep 1 

write-Host "I finished the cleanup task" -ForegroundColor Yellow 
##### End of the Script ##### ad