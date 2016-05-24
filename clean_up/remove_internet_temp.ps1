############################################################
## Remove Temporary Internet Files From User Profiles
##  Caution: Use at your own risk. 
##  No warranty expressed or implied.
## Written by: Greg Kjono on 12/1/2011
############################################################
$version = gwmi win32_operatingsystem | select version
$version = $version.version.substring(0,4)
$ErrorActionPreference = "Continue"

## Set profile root path based on OS.
if ($version -ge "6.0."){
 [STRING]$ds = "C:\Users\"
}else{
 [STRING]$ds = "C:\Documents and Settings\"
}

sl $ds
## Loop through each of the profiles and get temporary internet directories
foreach ($directory in get-childitem $ds -Force | where {$_.PsIsContainer}){
 $dir =  $ds + $directory + "\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.IE5"
 get-childitem $dir -Force -Recurse | where {$_.PsIsContainer} | Remove-Item -Force 
}

## Delete any temporary internet files in %windir%\temp
$WinTempInet = $env:windir + '\temp\Temporary Internet Files\Content.IE5'
if ($WinTempInet){
 sl $WinTempInet
 foreach ($WinTempInetDir in get-childitem $WinTempInet -Force | where {$_.PsIsContainer}){
  get-childitem $WinTempInetDir -Force | where {$_.PsIsContainer} | Remove-Item -Force -Recurse
 }
}