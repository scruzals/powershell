
param(
[string]$rgname,
[string] $saname,
[string] $sargname,
[int] $vhdsize
)

$VirtualMachines = Get-AzureRmVM -ResourceGroupName $rgname
[int]$i=1

foreach ($VirtualMachine in $VirtualMachines)
{
$a= $i.ToString().PadLeft(4,'0')
$StorageAccount = Get-AzureRmStorageAccount -Name $saname -ResourceGroupName $sargname
write-host adding disk to $VirtualMachine.Name using storage account $StorageAccount.StorageAccountName
$vhdURI=$StorageAccount.PrimaryEndpoints.Blob.ToString()  + $VirtualMachine.Name + "/" + $VirtualMachine.Name +"app$i" +".vhd"
Add-AzureRmVMDataDisk -VM $VirtualMachine -Name Hints -DiskSizeInGB $vhdsize -VhdUri $vhdURI -CreateOption empty -Lun 2 
Update-AzureRmVM -ResourceGroupName $VirtualMachine.ResourceGroupName -VM $VirtualMachine
$i ++
}


    