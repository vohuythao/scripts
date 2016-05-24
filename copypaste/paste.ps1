$filePath = Read-Host " please enter file path for paste: "
function Set-FileContent($filePath)  
{  
     $command =  
     {  
         Add-Type -an System 
         Add-Type -an System.Windows.Forms  
         $filePathArg = $Args[0] 
         $encoded = [System.Windows.Forms.Clipboard]::GetText() 
         $content = [System.Convert]::FromBase64String($encoded) 
         [System.IO.File]::WriteAllBytes($filePathArg, $content) 
     }  
     powershell -sta -noprofile -args $filePath -command $command 
}

Set-FileContent $filePath