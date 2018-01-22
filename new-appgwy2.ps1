
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("rg")] 
        $resourcegroup,

        [Parameter()]
        [string]
        $listenerName = "httplistiner01",

        [Parameter(Mandatory=$true,
                   Position=2)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int]
        $FrontEndPortnumber,

        [Parameter(Mandatory=$true,
                   Position=3)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int]
        $backendportnumber,

        [Parameter(Mandatory=$false,
                   Position=4)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Small", "Medium", "Large")]
        $size="Small",

        [Parameter(Mandatory=$false,
                   Position=5)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $instancecount="2",

         [Parameter(Mandatory=$true,
                   Position=6)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("eastus", "westus")]
        $location,
        
        [Parameter(Mandatory=$false,
                   Position=7)]
        [bool] $pip = $false,
        
        [Parameter(Mandatory=$false,
                   Position=8)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int]$gwcount = 1,

        [Parameter(Mandatory=$true,
                   Position=9)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [guid]
        $subscriptionID
    )
     Select-AzureRmSubscription -SubscriptionId $subscriptionID
     $ags= Get-AzureRmApplicationGateway -ResourceGroupName $resourcegroup -ErrorAction SilentlyContinue
     $agcount = $ags.count
     $nics = get-azurermnetworkinterface -ResourceGroupName $ResourceGroup | where VirtualMachine  -NE $null #skip Nics with no VM
     $obj=@() 
     $aggnumber = $agcount + $gwcount

    for($i=$agcount + 1 ; $i -le $aggnumber; $i++)
        {
            $agname = ($resourcegroup.TrimEnd('-rg'))+"-ag0" + $i
            $agipname= ($resourcegroup.TrimEnd('-rg'))+"-ip0" + $i
            $agsize = "Standard_" + $size
            $agobject = New-Object –TypeName PSObject
            $agobject | Add-Member –MemberType NoteProperty –Name appgwyname –Value $agname
            $agobject | Add-Member –MemberType NoteProperty –Name appgwypipname –Value $agipname
            $agobject | Add-Member –MemberType NoteProperty –Name frontendport –Value $FrontEndPortnumber
            $agobject | Add-Member –MemberType NoteProperty –Name backendport –Value $backendportnumber
            $agobject | Add-Member –MemberType NoteProperty –Name location –Value $location
            $agobject | Add-Member –MemberType NoteProperty –Name size –Value $agsize
            $agobject | Add-Member –MemberType NoteProperty –Name instancecount –Value $instancecount
            $agobject | Add-Member –MemberType NoteProperty –Name resourcegroup –Value $resourcegroup
            $agobject | Add-Member –MemberType NoteProperty –Name nics –Value $nics
            $agobject | Add-Member –MemberType NoteProperty –Name listenerName –Value $listenerName
            $agobject | Add-Member –MemberType NoteProperty –Name pip –Value $pip
            $obj += $agobject
        }
   

    
  
    $obj | Start-RSJob -ScriptBlock {
            param($object)
            $VNet = Get-AzureRmvirtualNetwork -Name "muse1-np01-n001-vn01" -ResourceGroupName "MUSE1-NP01-N001" 
            $Subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name "AppGateways" -VirtualNetwork $VNet
            $GatewayIPconfig = New-AzureRmApplicationGatewayIPConfiguration -Name $object.appgwyname -Subnet $Subnet
            $Probe = New-AzureRmApplicationGatewayProbeConfig -Name "Probe01" -Protocol Http -HostName "127.0.0.1" -Path "/" -Interval 30 -Timeout 30  -UnhealthyThreshold 8
            $Pool = New-AzureRmApplicationGatewayBackendAddressPool -Name "Pool01" -BackendIPAddresses ($object.nics.IpConfigurations | select-object -ExpandProperty PrivateIpAddress)
            $PoolSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name "PoolSetting01"  -Port $object.backendport -Protocol "Http" -CookieBasedAffinity "Disabled" -Probe $Probe
            $FrontEndPort = New-AzureRmApplicationGatewayFrontendPort -Name "FrontEndPort01"  -Port $object.Frontendport

            if($Object.pip)
            {
            # Create a public IP address
            #write-host Creating PIP -
            $PublicIp = New-AzureRmPublicIpAddress -ResourceGroupName $object.ResourceGroup -Name $object.appgwypipname -Location $object.location -AllocationMethod "Dynamic"
            $FrontEndIpConfig = New-AzureRmApplicationGatewayFrontendIPConfig -Name "FrontEndConfig01" -PublicIPAddress $PublicIp 
            }
            else
            {
            $FrontEndIpConfig = New-AzureRmApplicationGatewayFrontendIPConfig -Name "FrontEndConfig01" -Subnet $Subnet
            }

            $Listener = New-AzureRmApplicationGatewayHttpListener -Name $object.listenerName  -Protocol "Http" -FrontendIpConfiguration $FrontEndIpConfig -FrontendPort $FrontEndPort
           
            $Rule = New-AzureRmApplicationGatewayRequestRoutingRule -Name "Rule01" -RuleType basic -BackendHttpSettings $PoolSetting -HttpListener $Listener -BackendAddressPool $Pool
            $Sku = New-AzureRmApplicationGatewaySku -Name $object.size -Tier Standard -Capacity $object.instancecount
            $Gateway = New-AzureRmApplicationGateway -Name $object.appgwyname -ResourceGroupName $object.resourcegroup -Location $object.location -BackendAddressPools $Pool -BackendHttpSettingsCollection $PoolSetting -FrontendIpConfigurations $FrontEndIpConfig  -GatewayIpConfigurations $GatewayIpConfig -FrontendPorts $FrontEndPort -HttpListeners $Listener -RequestRoutingRules $Rule -Sku $Sku -Probes $Probe
        } -ModulesToImport azure*
     
   
