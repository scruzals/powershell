[CmdletBinding(SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0
                   )]
        [string]
        $ResourceGroupName,

        [Parameter(Mandatory=$true, 
                    Position=1)]
        [string]
        $SubscriptionID,
        [Parameter(Mandatory=$true, 
                    Position=1)]
        [string]
        $nsgname,

        [switch] $remove
)
$ErrorActionPreference="stop"
$action="applying"
write-host switching Azure subscrition -ForegroundColor Yellow
Select-AzureRmSubscription -SubscriptionId $subscriptionID

$nics= Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName

if($remove.IsPresent)
{
    $nsg=$null
    $action= "removing"
}
else
{
    $nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $nsgname
 }
if ($nics.count -eq 0)
{
    write-host No NICs found in Resource group $ResourceGroupName. Ensure proper resource group is selected -ForegroundColor Yellow
    exit
}
else
{
    foreach ($nic in $nics)
        {
            write-host $action $nsg.Name to (($nic.Id).split('/'))[-1] -ForegroundColor yellow
            $nic.NetworkSecurityGroup = $nsg
            $result= Set-AzureRmNetworkInterface -NetworkInterface $nic
            if ($result.ProvisioningState -eq "Succeeded")
            {
             write-host $nsg.name $action completed sucessfuly -ForegroundColor Green
            }
        }
    Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName | select name, NetworkSecurityGroupText
}