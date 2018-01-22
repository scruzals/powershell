$ErrorActionPreference="stop"
$WarningPreference="SilentlyContinue"
$outboungnsg = Import-Csv C:\Users\russell_norton\Desktop\azure-powershell\beta\baseline_GSO_NSG_prod_nonprod.csv
Select-AzureRmSubscription -SubscriptionId <subid>
$vnet = Get-AzureRmVirtualNetwork -Name <vnetname> -ResourceGroupName <vnetrg>
$nsgTags = @{Role="Core service NSG";Owner="DL-ENG-Norton_SRE@symantec.com"; Environment="Prod"}

write-host Create App NSG -ForegroundColor Cyan
$appnsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName MUSW1-NN01-N001 -Location westus -Name "App-NSG" -force -Tag $nsgtags

foreach ($rule in $outboungnsg)
{
$appnsg | Add-AzureRmNetworkSecurityRuleConfig -Name $rule.name -Description $rule.comment -Access $rule.action -Protocol $rule.Services -Direction $rule.direction -Priority $rule.Priority  -SourceAddressPrefix $rule.source -SourcePortRange $rule.srcports -DestinationAddressPrefix $rule.destination -DestinationPortRange $rule.destport | out-null
}                   
write-host Set APP NSG -ForegroundColor Cyan
$ansgstatus = $appnsg | Set-AzureRmNetworkSecurityGroup 

write-host Create Support NSG -ForegroundColor Cyan
$supportnsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName MUSW1-NN01-N001 -Location westus -Name "Support-NSG" -force -Tag $nsgtags

foreach ($rule in $outboungnsg)
{
$supportnsg | Add-AzureRmNetworkSecurityRuleConfig -Name $rule.name -Description $rule.comment -Access $rule.action -Protocol $rule.Services -Direction $rule.direction -Priority $rule.Priority  -SourceAddressPrefix $rule.source -SourcePortRange $rule.srcports -DestinationAddressPrefix $rule.destination -DestinationPortRange $rule.destport | Out-Null
}                   
write-host Set Support NSG -ForegroundColor Cyan
$snsgstatus = $supportnsg | Set-AzureRmNetworkSecurityGroup

write-host Apply App NSG -ForegroundColor Cyan
Set-AzureRmVirtualNetworkSubnetConfig -Name app -AddressPrefix 10.142.132.0/22 -VirtualNetwork $vnet -NetworkSecurityGroup $appnsg | Out-Null
write-host Apply Support NSG -ForegroundColor Cyan
Set-AzureRmVirtualNetworkSubnetConfig -Name support -AddressPrefix 10.142.130.0/23 -VirtualNetwork $vnet -NetworkSecurityGroup $supportnsg  | Out-Null 
write-host Set network -ForegroundColor Cyan
$status =Set-AzureRmVirtualNetwork -VirtualNetwork $vnet 

$status.ProvisioningState 