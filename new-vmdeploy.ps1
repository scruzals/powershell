#needs posh-rsjob module
param(
[switch]$force,

[Parameter(Mandatory=$true)]
[string] $vmconfig,
[Parameter(Mandatory=$true)]
[guid] $subscription
)
$ErrorActionPreference="stop"
write-host Switching subscription
Select-AzureRmSubscription -SubscriptionId $subscription
$data = Import-Csv $vmconfig
$data | fl
foreach( $item in $data)
{

$resourceGroupchk =  Get-AzureRmResourceGroup -Name $item.ResourceGroupName -Location $item.location -ErrorAction SilentlyContinue
    if(!$ResourceGroupchk)
    {
      
        if($force.IsPresent)
            {   write-host Resource group $item.ResourceGroupName does not exist. Creating
                New-AzureRmResourceGroup -ResourceGroup $item.ResourceGroupName -location $item.Location -Tag @{Role = "VMstorage";  contact = $item.owner; environment="Prod"; Platform=$item.platform} 
            }
        else
        {
         write-host Resource group $item.ResourceGroupName does not exist Exiting -ForegroundColor red
         exit
            
        }
    }
    else
    {
        write-host RG exists -ForegroundColor Green
    }
<#$sachk =  Get-AzureRmStorageAccount -Name $item.StorageName  -ResourceGroupName $item.ResourceGroupName  -ErrorAction SilentlyContinue
    if(!$sachk)
    {
      
        if($force.IsPresent)
            {   write-host Storage Account $item.StorageName does not exist. Creating
                New-AzureRmStorageAccount -ResourceGroupName $item.ResourceGroupName -Name $item.StorageName -SkuName $item.Storagetype -Location $item.location -Tag @{Role = "VMstorage";  contact = $item.owner; environment="Prod"; Platform=$item.platform} 
            }
        else
       {
         write-host Storage Account $item.StorageName does not exist Exiting -ForegroundColor red
         exit
            
        }
    }
    else
    {
        write-host SA exists -ForegroundColor Green
    }#>
$AvailabiltySetchk =  Get-AzureRmAvailabilitySet -Name $item.AvailabilitySet -ResourceGroupName $item.ResourceGroupName -ErrorAction SilentlyContinue
    if(!$AvailabiltySetchk)
    {
      
        if($force.IsPresent)
            {   write-host Availabilty  Set $item.AbvailabiltySet does not exist. Creating
                New-AzureRmAvailabilitySet -ResourceGroup $item.ResourceGroupName -location $item.Location -Name $item.AvailabilitySet -PlatformUpdateDomainCount 3 -PlatformFaultDomainCount 3 -Managed 
            }
        else
        {
         write-host Availabilty  Set $item.AbvailabiltySet does not exist does not exist Exiting -ForegroundColor red
         exit
            
        }
    }
    else
    {
        write-host AS exists -ForegroundColor Green
    }
}
write-host start pipeline  -ForegroundColor Green
$data | Start-RSJob -Throttle 200 -ScriptBlock{
    param($object)
    $image = $object.imagepath
    $AvailabilitySetName=$object.AvailabilitySet     
    $ResourceGroupName = $object.ResourceGroupName
    $Location = $object.Location
    $UserName = $object.UserName
    $VNetResourceGroup = $object.VNetResourceGroup
    $vmtags=@{Role= $object.role ; Owner=$object.owner; App= $object.app; environment= $object.env; appid= $object.appid; Platform= $object.platform;  AppRole= $object.AppRole; BusinessUnit= $object.BusinessUnit }
    $datadisk = $object.datadisk
    ## Storage
    $StorageName = $object.StorageName
    $StorageType = $object.StorageType
    ## Compute
    $VMName = $object.VMName
    $ComputerName = $VMName
    $VMSize = $object.VMSize
    $OSDiskName = $VMName + "OSDisk"

    ## Network
    $InterfaceName = $VMName + "_NIC01"
    $SubnetName = $object.SubnetName
    $VNetName = $object.VNetName
        
    
    $secpasswd = ConvertTo-SecureString “Symantec@123” -AsPlainText -Force
    $creds = New-Object System.Management.Automation.PSCredential ($object.UserName, $secpasswd)

    

    #NO USER DEFINED VARIABLES PAST THIS POINT 

           
        
    # Network
    $vnet = Get-AzureRmVirtualNetwork -Name $VNetName  -ResourceGroupName $VNetResourceGroup
    
    #$StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName
    
    $subnet = $vnet.Subnets | where { $_.name -eq $SubnetName}
    $Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $subnet.id -force


    # Compute

    ## Setup local VM object
    $Credential = $creds
    $SourceImageUri = $image
    $AvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetName
    if($image -like "https*")
    {
    $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName
    $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetId $AvailabilitySet.id 
    $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -ComputerName $ComputerName -Windows  -Credential $Credential -EnableAutoUpdate -ProvisionVMAgent
    $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
    $OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
    $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -SourceImageUri $SourceImageUri -CreateOption FromImage -Windows
    New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine -Tags $vmtags
    }
    if ($image -eq "managed-windows")
    {
    $rgName = "muw1-inf-image-core-rg"
    $location = "westus"
    $imageName = "w2k12r2-062017"
    $image = Get-AzureRMImage -ImageName $imageName -ResourceGroupName $rgName

    #$cred = Get-Credential
    #New-AzureRmResourceGroup -Name rn-image-test-rg -Location eastus

    #$vmName = "rn-img-test-01"
    #$computerName = "myComputer"
    #$InterfaceName = $vmname + "nic_01"
    #$vmSize = "Standard_DS1_v2"
    $AvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetName
    $vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $AvailabilitySet.id 


    $vm = Set-AzureRmVMSourceImage -VM $vm -Id $image.Id

    $vm = Set-AzureRmVMOSDisk -VM $vm  -StorageAccountType PremiumLRS -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite
    $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $computerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate

    $vm = Add-AzureRmVMNetworkInterface -VM $vm  -Id $Interface.Id

    New-AzureRmVM -VM $vm -ResourceGroupName $ResourceGroupName -Location $location -Tags $vmtags

    }
    if ($image -eq "managed")
    {
    $rgName = "muw1-inf-image-core-rg"
    $location = "westus"
    $imageName = "cent7-062017"
    $image = Get-AzureRMImage -ImageName $imageName -ResourceGroupName $rgName

    #$cred = Get-Credential
    #New-AzureRmResourceGroup -Name rn-image-test-rg -Location eastus

    #$vmName = "rn-img-test-01"
    #$computerName = "myComputer"
    #$InterfaceName = $vmname + "nic_01"
    #$vmSize = "Standard_DS1_v2"
    $AvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetName
    $vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $AvailabilitySet.id 
    #$vnet = Get-AzureRmVirtualNetwork -Name muse1-np01-n001-vn01  -ResourceGroupName MUSE1-NP01-N001
    #$subnet = $vnet.Subnets | where { $_.name -eq "test"}
    #$nic = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName rn-image-test-rg -Location $Location -SubnetId $subnet.id -force

    $vm = Set-AzureRmVMSourceImage -VM $vm -Id $image.Id

    $vm = Set-AzureRmVMOSDisk -VM $vm  -StorageAccountType PremiumLRS -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite
    $vm = Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $computerName -Credential $Credential

    $vm = Add-AzureRmVMNetworkInterface -VM $vm  -Id $Interface.Id

    New-AzureRmVM -VM $vm -ResourceGroupName $ResourceGroupName -Location $location -Tags $vmtags

    }
    if($image -eq "linux")
    {
    $AvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetName
    $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetId $AvailabilitySet.id 
    $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $ComputerName -Credential $Credential 
    $VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName OpenLogic -Offer Centos -Skus 7.2 -Version "latest"
    $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
    $OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd" 
    #$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri  -CreateOption FromImage -DiskSizeInGB 128
    $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine  -StorageAccountType PremiumLRS -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite
    if($datadisk -eq "yes")
    {
    $diskSize=512
    $diskLabel="APPStorage"
    $diskName= "-DISK02"
    $vhdURI=$StorageAccount.PrimaryEndpoints.Blob.ToString()  + "vhds/" + $vmName + $diskName  + ".vhd"
    Add-AzureRmVMDataDisk -VM $VirtualMachine -Name $diskLabel -DiskSizeInGB $diskSize -VhdUri $vhdURI -CreateOption empty
    }

    New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine -Tags $vmtags
    }

    if($image -eq "linux-6")
    {
    $AvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetName
    $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetId $AvailabilitySet.id 
    $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $ComputerName -Credential $Credential 
    $VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName OpenLogic -Offer Centos -Skus 6.6 -Version "latest"
    $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
    $OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd" 
    $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri  -CreateOption FromImage -DiskSizeInGB 128
    if($datadisk -eq "yes")
    {
    $diskSize=512
    $diskLabel="APPStorage"
    $diskName= "-DISK02"
    
    $vhdURI=$StorageAccount.PrimaryEndpoints.Blob.ToString()  + "vhds/" + $vmName + $diskName  + ".vhd"
    Add-AzureRmVMDataDisk -VM $VirtualMachine -Name $diskLabel -DiskSizeInGB $diskSize -VhdUri $vhdURI -CreateOption empty 
    }

    New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine -Tags $vmtags
    }
    if($image -eq "win")
    {
    $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize 
    $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -ComputerName $ComputerName -Windows -EnableAutoUpdate -ProvisionVMAgent -Credential $Credential 
    $VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest" 
    $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
    $OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
    $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage
    New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine -Tags $vmtags
    }
    else
    {
    write-host ping

    }
    ## Create the VM in Azure
    
     
 } -ModulesToImport azure*


 Get-RSJob | Wait-RSJob -ShowProgress
 foreach( $item in $data)
 {
$vms = get-azurermvm -ResourceGroupName $item.ResourceGroupName

$nics = get-azurermnetworkinterface -ResourceGroupName $item.ResourceGroupName | where VirtualMachine -NE $null #skip Nics with no VM

foreach($nic in $nics)
{
    $vm = $vms | where-object -Property Id -EQ $nic.VirtualMachine.id
    $prv =  $nic.IpConfigurations | select-object -ExpandProperty PrivateIpAddress
    $alloc =  $nic.IpConfigurations | select-object -ExpandProperty PrivateIpAllocationMethod
    Write-Output "$($vm.Name) : $prv , $alloc, $($vm.ResourceGroupName)"
}

}