
$data = Get-AzureRmNetworkInterface -ResourceGroupName <rgname>
$data | start-rsjob -Throttle 200 -ScriptBlock{
param($object)
$VNetName ="muse1-np02-n001-vn01"
$VNetResourceGroup = "MUSE1-NP02-N001"
$SubnetName= "shastaclt"

$vnet = Get-AzureRmVirtualNetwork -Name $VNetName  -ResourceGroupName $VNetResourceGroup
$subnet = $vnet.Subnets | where { $_.name -eq $SubnetName}

$object | set-AzureRmNetworkInterfaceIpConfig  -SubnetId $subnet.id -Name ipconfig1 | Set-AzureRmNetworkInterface
 }

 Get-RSJob | Wait-RSJob -ShowProgress