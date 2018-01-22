$ErrorActionPreference="continue"
#$filename= "nsg_properties.csv"
$data= Import-Csv C:\path\to\nsg.csv
foreach( $item in $data)
{
    $nsgname = $item.nsgname
    $nsgrg = $item.nsgrg
    $filename= $item.filename
    $nsglocation="eastus"
    $nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgname -ResourceGroupName $nsgrg -ErrorAction SilentlyContinue
    $nsgdata = Import-Csv C:\Users\russell_norton\Desktop\azure-powershell\beta\nsg_configs\$filename
    write-host Creating NSG $nsgname -ForegroundColor Yellow
    $nsg = New-AzureRmNetworkSecurityGroup -Name $nsgname -ResourceGroupName $nsgrg -Location $nsglocation -Force
    #if(!$nsg)
     #   {
      #  write-host Creating NSG $nsgname -ForegroundColor Yellow
       #  $nsg = New-AzureRmNetworkSecurityGroup -Name $nsgname -ResourceGroupName $nsgrg -Location $nsglocation
        #}
    foreach ($rule in $nsgdata)
        {
        $rule.Name.trim()
        $nsg | Add-AzureRmNetworkSecurityRuleConfig -Name $rule.name.trim() -Description $rule.comment -Access $rule.action -Protocol $rule.Services -Direction $rule.direction -Priority $rule.Priority  -SourceAddressPrefix $rule.source -SourcePortRange $rule.srcports -DestinationAddressPrefix $rule.destination -DestinationPortRange $rule.destport | out-null
        }  

    $result= $nsg | Set-AzureRmNetworkSecurityGroup 
    if ($result.ProvisioningState -eq "Succeeded")
    {
        write-host $nsg.name created sucessfully -ForegroundColor green
    }
    else {
     write-host $nsg.Name creation failed -ForegroundColor Red
     $error[0]
    }
}