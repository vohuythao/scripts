param(
 [string]$info_path
 )

 echo $info_path
 echo "Hello"

switch -wildcard ($info_path) 
    { 
        "*\PreQA*" {$environment = "PreQA"; echo $environment} 
        "*\QA*" {$environment = "QA"; echo $environment} 
        "*\DEV*" {$environment = "DEV"; echo $environment} 
        default {"The color could not be determined."}
    }