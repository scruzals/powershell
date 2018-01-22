
$rgs = Get-AzureRmResourceGroup -Name <rg name>
$output_file = "ips.csv"
#Write-Output ""hostname","ip","method","resourcegroup"" >> $output_file
foreach ($rg in $rgs)
{
    $vms = get-azurermvm -ResourceGroupName $rg.ResourceGroupName
    $nics = get-azurermnetworkinterface -ResourceGroupName $rg.ResourceGroupName | where VirtualMachine  -NE $null #skip Nics with no VM
    write-host $rg.resourcegroupname
    foreach($nic in $nics)
        {
            $vm = $vms | where-object -Property Id -EQ $nic.VirtualMachine.id
            $prv =  $nic.IpConfigurations | select-object -ExpandProperty PrivateIpAddress
            $alloc =  $nic.IpConfigurations | select-object -ExpandProperty PrivateIpAllocationMethod
            Write-Output ""$($vm.Name)", "$prv" , "$alloc", "$($vm.ResourceGroupName)"" #>> $output_file
        }
}