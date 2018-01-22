function copy-azureudr {
    param(
    [string] $udrname,
    [string] $udrrg,
    [string] $newudrname
    )
    $ErrorActionPreference="stop"
    $routes=$null
    $routetable = Get-AzureRmRouteTable -Name $udrname -ResourceGroupName $udrrg
    $routes = $routetable.Routes

    #create UDR
    write-host Copying $udrname to $newudrname
    $newrouteTable = new-AzureRmRouteTable -Name $newudrname -ResourceGroupName $udrrg -Location $routetable.Location -Force
    # Add a route to the UDR Table
    foreach ($route in $routes)
    {
        $newrouteTable | Add-AzureRmRouteConfig -Name $route.Name -AddressPrefix $route.AddressPrefix -NextHopType $route.NextHopType -NextHopIpAddress $route.NextHopIpAddress 
    }
    $newroutetable | Set-AzureRmRouteTable
}


function migrate-azureudr {
    param(
    [string] $udrnames,
    [string] $udrrg,
    [string] $oprigasasip,
    [string] $newasaip

    )
    $ErrorActionPreference="stop"
    $routes=$null
    foreach($udrname in $udrnames)
    {
        $routetable = Get-AzureRmRouteTable -Name $name -ResourceGroupName $udrrg
        $routes = $routetable.Routes

        write-host Migrating $name
        #create UDR

        $newrouteTable = new-AzureRmRouteTable -Name $name -ResourceGroupName $udrrg -Location $routetable.Location

        #$routetable.Routes.Clear()
        # Add a route to the UDR Table
        foreach ($route in $routes)
        {
            #$route
            if($route.NextHopIpAddress -eq "$oprigasasip")
            {
            $asaip= "newasaip"
            $newrouteTable | add-AzureRmRouteConfig -Name $route.Name -AddressPrefix $route.AddressPrefix -NextHopType $route.NextHopType -NextHopIpAddress $asaip
            }
            else{
            $newrouteTable | add-AzureRmRouteConfig -Name $route.Name -AddressPrefix $route.AddressPrefix -NextHopType $route.NextHopType -NextHopIpAddress $route.NextHopIpAddress 
            }

        }

        $newroutetable | Set-AzureRmRouteTable
    }
}

function update-asanexthop {

param(
[string] $udrnames,
[string] $udrrg,
[string] $oprigasasip,
[string] $newasaip

)

$ErrorActionPreference="stop"
$routes=$null
$names = @()
foreach($name in $names)
    {
    $routetable = Get-AzureRmRouteTable -Name $name -ResourceGroupName $udrrg
    $routes = $routetable.Routes

    write-host Updating $name

    foreach ($route in $routes)
    {
    #$route
    if($route.NextHopIpAddress -eq "$oprigasasip")
    {
    $asaip= "$newasaip"
    $routeTable | Set-AzureRmRouteConfig -Name $route.Name -AddressPrefix $route.AddressPrefix -NextHopType $route.NextHopType -NextHopIpAddress $asaip
    }
    else{
    $routeTable | Set-AzureRmRouteConfig -Name $route.Name -AddressPrefix $route.AddressPrefix -NextHopType $route.NextHopType -NextHopIpAddress $route.NextHopIpAddress 
     }

    }

    $routetable | Set-AzureRmRouteTable
    }
}