<#
.Synopsis
   Update/create Subnets on an existing Azure VNet
.DESCRIPTION
   Update/create Subnets on an existing Azure VNet
.EXAMPLE
   update-subnets.ps1 -configfile .\config.xml

.INPUTS
   XML config file
.OUTPUTS
   none

#>

param
([Parameter(Mandatory=$true, 
                   Position=0
                   )]
        [ValidateNotNullOrEmpty()]
        [string]
        $configfile,
        [switch] $forcecretevnet

        )

function update-vnet
{
                        
                        write-host creating Subnets -ForegroundColor Cyan
                        write-host creating NSGs -ForegroundColor Cyan
                    
                        $rule1 = New-AzureRmNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP"  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100  -SourceAddressPrefix 155.64.0.0/16 -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
                        $rule2 = New-AzureRmNetworkSecurityRuleConfig -Name web-rule -Description "Allow HTTP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 101  -SourceAddressPrefix 155.64.0.0/16 -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80 
                        $rule3 = New-AzureRmNetworkSecurityRuleConfig -Name ssh-rule -Description "Allow SSH"  -Access Allow -Protocol Tcp -Direction Inbound -Priority 102  -SourceAddressPrefix 155.64.0.0/16 -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
                        $rule4 = New-AzureRmNetworkSecurityRuleConfig -Name web-secure-rule -Description "Allow HTTPS" -Access Allow -Protocol Tcp -Direction Inbound -Priority 103  -SourceAddressPrefix 155.64.0.0/16 -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443
                        $rule5 = New-AzureRmNetworkSecurityRuleConfig -Name Deny-All -Description "Deny All" -Access Deny -Protocol Tcp -Direction Inbound -Priority 4000  -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *
                        $defaultnsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $config.config.resourcegroup.name -Location $config.config.resourcegroup.location -Name "Default-NSG" -SecurityRules $rule1,$rule2,$rule3,$rule4, $rule5 -force -Tag $nsgtags
                        
                        foreach ($subnet in $subnets )

                            {
                              try
                              {
                              $subnet
                              Add-AzureRmVirtualNetworkSubnetConfig -AddressPrefix $subnet.addressspace -Name $subnet.name -VirtualNetwork $vnet -RouteTableId /subscriptions/3534678c-6ea4-44c2-bdc7-f2cde02cbd23/resourceGroups/MEUW1-NP01-N001/providers/Microsoft.Network/routeTables/ROUTE-to-ASA-Inside #-NetworkSecurityGroup $defaultnsg
                              Write-Host adding $subnet.name -ForegroundColor Cyan
                              }
                              catch
                              {
                                Write-host $subnet.name already exists -ForegroundColor Yellow
                                Write-Verbose $error
                                continue
                              }
                            }
                        
                        write-host Applying network config -ForegroundColor Cyan

                        $setsubnets = Set-AzureRmVirtualNetwork -VirtualNetwork $vnet 
                        
                        if($subnets)
                        {
                        write-host Subnets configured sucessfuly -ForegroundColor green
                        }

                        else
                        {
                         write-host Network apply -ForegroundColor Red
                         $error[0] 
                        }
}
$ErrorActionPreference="stop"
[xml] $config = Get-Content $configfile
$subid=$config.config.subscription.id
$subnets = $config.config.network.subnets.subnet 
#$ErrorActionPreference="stop"
$networktags=@{Role="Core service";Owner="me"; environment="Prod"}
$nsgTags = @{Role="Core service NSG";Owner="me"; Environment="Prod"}

write-host Switching to $config.config.subscription.name -ForegroundColor Green
Select-AzureRmSubscription -SubscriptionId $subid 

         write-host Getting vnet -ForegroundColor Cyan
                $vnet = get-AzureRmVirtualNetwork -Name $config.config.network.vnet.name -ResourceGroupName $config.config.resourcegroup.name  
                if($vnet)
                    {
                        write-host vnet found -ForegroundColor Green
                        update-vnet
                    
                    }
                
         else
                    {
                        write-host vnet not found -ForegroundColor Red
                        break              
                    }
