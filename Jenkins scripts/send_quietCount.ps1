Param($runtime, $url)
## A function to calculate difference betwwen current time and expected runtime
Function GetTimeDifference
{
$Time1 = "$runtime"
$Time2 = Get-Date -format HH:mm:ss
$TimeDiff = New-TimeSpan $Time2 $Time1
if ($TimeDiff.Seconds -lt 0) {
	$Hrs = ($TimeDiff.Hours) + 23
	$Mins = ($TimeDiff.Minutes) + 59
	$Secs = ($TimeDiff.Seconds) + 59 }
else {
	$Hrs = $TimeDiff.Hours
	$Mins = $TimeDiff.Minutes
	$Secs = $TimeDiff.Seconds }
$Difference = '{0:00}:{1:00}:{2:00}' -f $Hrs,$Mins,$Secs
$global:duration = $Hrs*3600 + $Mins*60 + $Secs
}

## Send a quietCount period to Auto-test ##
$user = "vnguyen"
$pass = "2214f638ead54791fc59d2d277653b7d"
$pair = "${user}:${pass}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"
$headers = @{ Authorization = $basicAuthValue }
GetTimeDifference
echo "Configuring Auto-test Cool quietCount to $duration seconds"
Invoke-WebRequest -Uri $url -Headers $headers -Method Post -Body "<project><quietPeriod>$duration</quietPeriod></project>"
echo $duration