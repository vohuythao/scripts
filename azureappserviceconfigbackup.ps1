##variables
$resourcegroup = "name_of_resourcegroup"
$subscription = "subscription_id"
##get list of current appservice in this resource group
$name = (az resource list --subscription $subscription --resource-group $resourcegroup --query "[?type=='Microsoft.Web/sites']" | select-string name)
ForEach ($line in $name) {
$splitUp = $line -split "\s+" -split ","
$appname1=$splitUp[2]
$appname2=$appname1 -split [regex]::escape("""")
echo $appname2 >> test.txt}
(gc test.txt) | ? {$_.trim() -ne "" } | set-content appservicelist.txt

##get appservice config
mkdir .\appserviceconfigbackup\$resourcegroup
$appservicelist=(cat .\appservicelist.txt)
Foreach ($appservice in $appservicelist) {

az webapp config appsettings list --name $appservice  -g $resourcegroup > .\appserviceconfigbackup\$resourcegroup\$appservice.json
}

##remove appservicelist.txt
rm appservicelist.txt
rm test.txt
