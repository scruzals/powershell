$creds = Get-Credential

Login-AzureRmAccount -Credential $creds
Select-AzureRmSubscription -SubscriptionId <subid>

$sa = Get-AzureRmStorageUsage

if ($sa.CurrentValue -le ($sa.Limit - 75))
{
    write-host 0 check_storage - storage accounts OK! $sa.CurrentValue of $sa.Limit accounts used 
    exit 0
}
else
{
    write-host 2 check_storage - we have a problem!!! $sa.CurrentValue of $sa.Limit accounts used
    exit 2
}