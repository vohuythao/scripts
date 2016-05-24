#Connect to vcenter server  
Connect-VIServer -Server 10.9.0.169 -Protocol https -User root -Password abc#1234

# Tao list VMs name 
Get-VM | select Name | Export-Csv vmname_169.csv –NoTypeInformation

#Import vm name from csv file  
Import-Csv vmname_169.csv |  
foreach {  
    $strNewVMName = $_.name  
      
    #Update VMtools without reboot  
    Get-VM $strNewVMName | Update-Tools –NoReboot -RunAsync
    write-host "Updated $strNewVMName ------ "  
       
    $report += $strNewVMName  
}  
write-host "Sleeping ..."  
Sleep 120  
#Send out an email with the names  
$emailFrom = "Test@hello.com"  
$emailTo = "t.vo@aswigsolutions.com"  
$subject = "VMware Tools Updated"  
$smtpServer = "10.9.0.22"  
$smtp = new-object Net.Mail.SmtpClient($smtpServer)  
$smtp.Send($emailFrom, $emailTo, $subject, $Report)  