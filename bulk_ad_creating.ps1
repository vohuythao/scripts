Import-Module ActiveDirectory
$path     = Split-Path -parent $MyInvocation.MyCommand.Definition
$newpath  = $path + "\ADUserList1.csv"
$Users = Import-Csv -Path "$newpath"            
foreach ($User in $Users)            
{            
    $Displayname = $User.'Firstname' + " " + $User.'Lastname'            
    $UserFirstname = $User.'Firstname'            
    $UserLastname = $User.'Lastname'            
    $OU = $User.'OU'            
    $SAM = $User.'SAM'            
    $UPN = $User.'SAM' + "@" + $User.'Maildomain'            
    $Description = $User.'Description'            
    $Password = $User.'Password'            
    New-ADUser -Name "$Displayname" -DisplayName "$Displayname" -SamAccountName $SAM -UserPrincipalName $UPN -GivenName "$UserFirstname" -Surname "$UserLastname" -Description "$Description" -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -Enabled $true -Path "$OU" -ChangePasswordAtLogon $false –PasswordNeverExpires $true            
    Add-ADGroupMember "Terminal Server Users" $User.'SAM'
}
