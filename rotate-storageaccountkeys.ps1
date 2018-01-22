<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>


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
        $StorageAccountName,

        [Parameter(Mandatory=$true, 
                    Position=2)]
        [string]
        $SubscriptionID
)
$ErrorActionPreference="stop"
write-host switching Azure subscrition
Select-AzureRmSubscription -SubscriptionId $subscriptionID

$storageaccountkeys = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
write-host Current Storage keys
$storageaccountkeys[0]
$storageaccountkeys[1]
Write-host Genertaing new Storage account keys
New-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName -keyName "key1"
New-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName -keyName "key2"
write-host New Storage account keys
$storageaccountkeys = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$storageaccountkeys[0]
$storageaccountkeys[1]
write-host creating new SAS token for key 1
$sac = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountkeys[0].Value
$saskey = $sac| New-AzureStorageAccountSASToken -Service Blob,File,Table,Queue -ResourceType Service,Container,Object -Permission rl -ExpiryTime (get-date).AddDays(90)
write-host New SAS key: $saskey