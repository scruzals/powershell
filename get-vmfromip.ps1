Select-AzureRmSubscription -SubscriptionName <subneme>
$westnic = Get-AzureRmNetworkInterface

Select-AzureRmSubscription -SubscriptionName <subneme>
$eastnic = Get-AzureRmNetworkInterface

Select-AzureRmSubscription -SubscriptionName <subneme>
$eastcorenic = Get-AzureRmNetworkInterface

Select-AzureRmSubscription -SubscriptionName <subneme>
$westcorenic = Get-AzureRmNetworkInterface
$nics = $westnic + $eastnic + $eastcorenic + $westcorenic
$sendaddr = @("10.82.98.4","10.142.114.54","10.82.114.35","10.142.114.10","10.142.114.6","10.142.114.5","10.142.114.9","10.142.114.8","10.142.114.33","10.142.114.4")
$recaddr = @("10.142.114.28","10.142.98.16","10.82.114.14","10.142.114.52","10.82.114.18","10.82.116.172","10.82.116.173","10.82.116.19","10.82.116.137","10.82.116.16")
Write-Host send
foreach ($nic in $nics)
{
    
    foreach($addr in $sendaddr)
    {
      
       if ($nic.IpConfigurations[0].PrivateIpAddress -eq $addr){
       write-host $nic.IpConfigurations[0].PrivateIpAddress ($nic.VirtualMachine.Id).Split('/')[-1]
       } 
    }
}
write-host ""
Write-Host recive
foreach($nic in $nics)
{

    foreach($addr in $recaddr)
    {
       
       if ($nic.IpConfigurations[0].PrivateIpAddress -eq $addr){
       write-host $nic.IpConfigurations[0].PrivateIpAddress ($nic.VirtualMachine.Id).Split('/')[-1]       
       } 
    }
}