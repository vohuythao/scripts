$date1 = Get-Date 06/20/15
$date2 = Get-Date 06/23/15

$Computername = Read-Host "Enter Computername Here"

Foreach ($Computer in $Computername)

    {
        $UserProperty = @{n="User";e={(New-Object System.Security.Principal.SecurityIdentifier $_.ReplacementStrings[1]).Translate([System.Security.Principal.NTAccount])}}
        $TypeProperty = @{n="Action";e={if($_.EventID -eq 7001) {"Logon"} else {"Logoff"}
        }}
        $TimeProeprty = @{n="Time";e={$_.TimeGenerated}}

        Get-EventLog -ComputerName $Computer System -Source Microsoft-Windows-Winlogon -After $date1 -Before $date2 | select $UserProperty,$TypeProperty,$TimeProeprty | Out-File c:\logons_.txt
    }