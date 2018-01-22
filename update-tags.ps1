$rgs= Get-AzureRmResourceGroup 
foreach ($rg in $rgs){
$group = Get-AzureRmResourceGroup -Name $rg.resourcegroupname
$parts= $rg.split('-')
if ($group.Tags.Count -ne 0)
    {
        $resources = Find-AzureRmResource -ResourceGroupName $group.ResourceGroupName
        #write-host appling tags to resources in $group.ResourceGroupName
        continue

        #$vmtags=@{Platform= $parts[1]; AppRole= $parts[2]; environment= "Prod"; BusinessUnit="NortonENG" }
        foreach($r in $resources)
        {
            try{
              #$r | Set-AzureRmResource -Tags $group.Tags -Force
            }
            catch{
                Write-Host  $r.ResourceId + "can't be updated"
            }
        }

      }

    if ($group.tags.Count -eq 0)
    {
        $resources1 = Find-AzureRmResource -ResourceGroupName $group.ResourceGroupName
        Write-Host Resource group $group.ResourceGroupName has no tags
        $vmtags=@{Platform= $parts[1]; AppRole= $parts[2]; environment= "Prod"; BusinessUnit="NortonENG" }
        foreach($r1 in $resources1){
      
            try{
             $r1 | Set-AzureRmResource -Tags $vmtags -Force
             
            }
            catch{
                Write-Host  $r1.ResourceId + "can't be updated"
            }
        }
    }
}
