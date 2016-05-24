﻿# 
# www.sivarajan.com 
# Add User to a Group - PowerShell Script 
# 
Import-module ActiveDirectory  
Import-CSV "C:\Scripts\Users.csv" | % {  
Add-ADGroupMember -Identity TestGroup1 -Member $_.UserName  
} 