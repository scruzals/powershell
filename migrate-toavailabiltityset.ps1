## This script will recreate a virtual machine while preserving the original OS disk, data disks, and NICs ##
## in order to add the VM to an availability set.  It is assumed that managed disks are in use.            ##
 
#set variables

param(
    [Parameter(Mandatory=$true)]
    $rg,
    [Parameter(Mandatory=$true)]
    $vmName ,
    [Parameter(Mandatory=$true)]
    $AvailSetName,
    [Parameter(Mandatory=$true)]
    [guid]$SubscriptionId,
    $outFile = "C:\Scripts\temp\outfile_$vmName.txt"
    )
    $ErrorActionPreference="stop"
    Select-AzureRmSubscription -SubscriptionId $SubscriptionId
    [bool]$managed =$null
    #Get VM Details
    $OriginalVM = get-azurermvm -ResourceGroupName $rg -Name $vmName
    if (test-path $outFile )
    {
        write-host Writing VM config to $outFile
    }
    else
    {
        write-host Creating $outfile
        New-Item -ItemType file -Path $outFile -Force
        write-host Writing VM config to $outFile
    }
    #Output VM details to file
    "VM Name: " | Out-File -FilePath $outFile 
    $OriginalVM.Name | Out-File -FilePath $outFile -Append
 
    "Extensions: " | Out-File -FilePath $outFile -Append
    $OriginalVM.Extensions | Out-File -FilePath $outFile -Append
 
    "VMSize: " | Out-File -FilePath $outFile -Append
    $OriginalVM.HardwareProfile.VmSize | Out-File -FilePath $outFile -Append
 
    "NIC: " | Out-File -FilePath $outFile -Append
    $OriginalVM.NetworkProfile.NetworkInterfaces[0].Id | Out-File -FilePath $outFile -Append
 
    "OSType: " | Out-File -FilePath $outFile -Append
    $OriginalVM.StorageProfile.OsDisk.OsType | Out-File -FilePath $outFile -Append
 
    "OS Disk: " | Out-File -FilePath $outFile -Append
    $OriginalVM.StorageProfile.OsDisk.ManagedDisk.Id | Out-File -FilePath $outFile -Append
    $OriginalVM.StorageProfile.OsDisk.Vhd | Out-File -FilePath $outFile -Append
 
    if ($OriginalVM.StorageProfile.DataDisks) {
    "Data Disk(s): " | Out-File -FilePath $outFile -Append
    $OriginalVM.StorageProfile.DataDisks.ManagedDisk.Id | Out-File -FilePath $outFile -Append
    $OriginalVM.StorageProfile.DataDisks.Vhd | Out-File -FilePath $outFile -Append
    }
 

    $availSet = Get-AzureRmAvailabilitySet -ResourceGroupName $rg -Name $AvailSetName -ErrorAction Ignore
        if($availSet.Managed)
        {
            write-host vm is Availabilty set is Aligned $OriginalVM.name -ForegroundColor Cyan
            write-host do managed stuff -ForegroundColor Yellow
            $managed =$true
        }
        elseif ($OriginalVM.StorageProfile.OsDisk.Vhd -ne $null -and $OriginalVM.StorageProfile.OsDisk.ManagedDisk -eq $null)
        {
            write-host vm is using unmanaged disks $OriginalVM.name -ForegroundColor Cyan
            write-host do unmanaged stuff -ForegroundColor Yellow
            $managed = $false
        }
        elseif ($OriginalVM.StorageProfile.OsDisk.Vhd -eq $null -and $OriginalVM.StorageProfile.OsDisk.ManagedDisk -ne $null)
        {
            write-host vm is using managed disks $OriginalVM.name -ForegroundColor Cyan
            write-host do managed stuff -ForegroundColor Yellow
            $managed =$true
        }
        else
        {
            Write-host cant determian managed or unmanaged exiting
            break
        }
    
    if (-Not $availSet) {
        $skuoption = $null
            if($managed)
            {
            $skuoption = "Aligned"
            }
        else{
            $skuoption = "Classic"
            }
            $availset = New-AzureRmAvailabilitySet -ResourceGroupName $rg -Name $AvailSetName -Location $OriginalVM.Location -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2 -Sku $skuoption
        }
 
    #Create the basic configuration for the replacement VM
    $newVM = New-AzureRmVMConfig -VMName $OriginalVM.Name -VMSize $OriginalVM.HardwareProfile.VmSize -AvailabilitySetId $availSet.Id
    
    #crate Avialiabilty set
    if($managed)
        {
        Set-AzureRmVMOSDisk -VM $NewVM -ManagedDiskId $OriginalVM.StorageProfile.OsDisk.ManagedDisk.Id -CreateOption Attach -Linux
        }
    else
        {
        Set-AzureRmVMOSDisk -VM $NewVM -VhdUri $OriginalVM.StorageProfile.OsDisk.Vhd.Uri -CreateOption Attach -Linux -Name $OriginalVM.StorageProfile.OsDisk.Name
        }

    #Add Data Disks - make sure to change the StorageAccountType as needed
    foreach ($disk in $OriginalVM.StorageProfile.DataDisks ) { 
        if($managed)
        {
        Add-AzureRmVMDataDisk -VM $newVM -Name $disk.Name -ManagedDiskId $disk.ManagedDisk.Id -Caching $disk.Caching -Lun $disk.Lun -CreateOption Attach -DiskSizeInGB $disk.DiskSizeGB -StorageAccountType $disk.ManagedDisk.StorageAccountType
        }
        else{
        Add-AzureRmVMDataDisk -VM $newVM -Name $disk.Name -VhdUri $disk.Vhd -Caching $disk.Caching -Lun $disk.Lun -CreateOption Attach -DiskSizeInGB $disk.DiskSizeGB
        }
    }
 
    #Add NIC(s)
    foreach ($nic in $OriginalVM.NetworkProfile.NetworkInterfaces) {
        Add-AzureRmVMNetworkInterface -VM $NewVM -Id $nic.Id
 
    }
    #Remove the original VM
    Remove-AzureRmVM -ResourceGroupName $rg -Name $vmName -force
    
    #Create the VM
    New-AzureRmVM -ResourceGroupName $rg -Location $OriginalVM.Location -VM $NewVM -DisableBginfoExtension
    
    