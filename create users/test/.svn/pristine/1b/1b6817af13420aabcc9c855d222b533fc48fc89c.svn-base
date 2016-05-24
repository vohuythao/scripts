  param(
 [string]$VMs
 )

    #Email

$smtp_server = "10.9.0.22"
$recipients = "t.vo@aswigsolutions.com"
[string[]]$cc_recipients = "Vinh Nguyen <v.nguyen@aswigsolutions.com>", "Trang Tran <t.minh@aswigsolutions.com>"
$username = "user1@behappy.local"
$password = "password"
$secpasswd = ConvertTo-SecureString "$password" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("$username", $secpasswd)

    #Test variable

$global:connect_failed = $false

    #Function

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
            Write-Host "Connecting to "$VMs":"$Port" (TCP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Host "Connection successful";
            echo "Connect successfully to $VMs port $Port" 
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $VMs port $Port"  
            echo "Cannot connect to $VMs port $Port"
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
            Write-Host "Connecting to "$VMs":"$Port" (UDP)..";
            $test.Connect($RemoteServer, $Port);
            Write-Host "Connection successful";
            echo "Connect successfully to $VMs port $Port" 
        }
        Catch
        {
            Write-Host "Connection failed";
            echo "Cannot connect to $VMs port $Port"  
            echo "Cannot connect to $VMs port $Port" 
            $global:connect_failed = $true
            
        }
        Finally
        {
            $test.Dispose();
        }
    }
} #End function TestPort-VM


TestPort-VM -IPAddress $VMs -Port 3389 -Protocol TCP

#Send report email

 If ($connect_failed)
    { 
        Send-MailMessage -to $recipients -Cc $cc_recipients -from "Monitor Script <monitorscript@aswigsolutions.com>" -SmtpServer $smtp_server -Subject "[ALERT][QA] Jump machine monitoring" -priority High -Credential $mycreds -BodyAsHtml "Cannot connect to jump machine"
    }
    Else 
    {
        Write-Host "Everything is fine"
    }