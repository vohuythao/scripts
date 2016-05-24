$filePath = Read-Host " please enter file path for copy: "

function Get-FileContent($filePath)  
{  
     $command =  
     {  
         Add-Type -an System 
         Add-Type -an System.Windows.Forms  
         $filePathArg = $Args[0] 
         $content = [System.IO.File]::ReadAllBytes($filePathArg) 
         $encoded = [System.Convert]::ToBase64String($content) 
         [System.Windows.Forms.Clipboard]::SetText($encoded) 
     }  
     powershell -sta -noprofile -args $filePath -command $command 
}

Get-FileContent $filePath