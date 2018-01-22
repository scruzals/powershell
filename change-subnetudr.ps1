

$vnet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $vnetrg
$udr = Get-AzureRmRouteTable -name $name -ResourceGroupName $rg
$subnets = @("redis")
foreach ($subnet in $subnets)
{
Set-AzureRmVirtualNetworkSubnetConfig -Name $subnet -VirtualNetwork $vnet -RouteTableId $udr.id
}