$ids = $null
$ids = Get-AzureRmNetworkSecurityGroup | select id
$sa = <sdid>
$ws = <wsid> -ResourceGroupName oms
foreach ( $id in $ids)
{
$name = (($id.id).Split('/'))[-1]

$setdebug=$false
    $diag = Get-AzureRmDiagnosticSetting -ResourceId $id.id -ErrorAction Continue
    $diag.Logs | % {if ($_.enabled -ne $true){
    $setdebug = $true}}
    $setdebug = $true
    if ($setdebug)
    {
        write-host Setting debug for (($id.id).Split('/'))[-1]
        Get-AzureRmResource -ResourceId $id.id | Set-AzureRmDiagnosticSetting -StorageAccountId $sa -Enabled $true -RetentionEnabled $true -RetentionInDays 5 -ErrorAction Continue -WorkspaceId $null
        #$resource = Get-AzureRmResource -ResourceId $id.id 
        #Add-AzureDiagnosticsToLogAnalytics -ResourceForLogs $resource -WorkspaceResource $ws
        
    }
    else
    {
        write-host debug set for (($id.id).Split('/'))[-1]
        
    }

    }