
#Email

$smtp_server = "10.9.0.22"
$recipients = "t.vo@aswigsolutions.com"
[string[]]$cc_recipients = "Vinh Nguyen <v.nguyen@aswigsolutions.com>", "Trang Tran <t.minh@aswigsolutions.com>"
$username = "user1@behappy.local"
$password = "password"
$secpasswd = ConvertTo-SecureString "$password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("$username", $secpasswd)

Function TestPort-VM
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
            Write-Host "Connecting to $Names "$VMs":"$Port" (TCP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Host "Connection successful";
            echo "Connect successfully to $Names - $VMs port $Port" 
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $Names - $VMs port $Port"  
            echo "Cannot connect to $Names - $VMs port $Port" | Out-File .\report_$Host_IP.txt -Append 
            $global:connect_failed = $true
            
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
            Write-Host "Connecting to $Names "$VMs":"$Port" (UDP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Host "Connection successful";
            echo "Connect successfully to $Names - $VMs port $Port" 
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $Names - $VMs port $Port"  
            echo "Cannot connect to $Names - $VMs port $Port" | Out-File .\report_$Host_IP.txt -Append 
            $global:connect_failed = $true
            
        }
        Finally
        {
            $test.Dispose();
        }
    }
} #End function TestPort-VM

Function CheckRDP
{
    Param($Host_IP)
    Get-VM | Select Name, PowerState, @{N="ip";E={@($_.guest.IPAddress[0])}}, @{N="toolstatus";E={@($_.ExtensionData.Guest.ToolsVersionStatus)}},  @{N="toolversion";E={@($_.ExtensionData.config.tools.toolsVersion)}} | Export-Csv vm_ip.csv -NoTypeInformation

            Import-Csv vm_ip.csv |  
            foreach {  
            $VMs = $_.ip
            $Names = $_.Name

            If ($_.PowerState -eq "PoweredOn")
            {
                If ($VMs) 
                {
                    #Test RDP for each VM
                    TestPort-VM -IPAddress $VMs -Port 3389 -Protocol TCP 
                }
                Else
                {
                    Send-MailMessage -to $recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "Cannot get IP" -Credential $mycreds -BodyAsHtml "Cannot get IP of $Names, use VMs name instead"
                    Write-Host "Cannot get IP of $Names, use VMs name instead" 
                    TestPort-VM -ComputerName $Names -Port 3389 -Protocol TCP
                }
                
            }
            Else 
            {
                echo "$Names is powered off" | Out-File .\report_$Host_IP.txt -Append
            }
    } #end for each VMs loop  

}

$time = 1

do {

    CheckRDP 10.9.0.84

 $time++
    sleep 10

} until ($time -eq 0) 