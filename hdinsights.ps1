param(
# If you have multiple subscriptions, set the one to use
[Parameter(Mandatory=$True, Position=1)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
    [guid]$subscriptionID, 
[Parameter(Mandatory=$True, Position=2)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
    [string]$subnetname = "hdinsightsubnet",
[Parameter(Mandatory=$True, Position=3)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
    [string]$vnetname = "virtualnetworkhdinsight",
[Parameter(Mandatory=$True, Position=4)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
    [string]$vnetrg = "russellhdinsight",
# Get user input/default values
[Parameter(Mandatory=$True, Position=5)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
    [string]$resourceGroupName,
[Parameter(Mandatory=$True, Position=6)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
[ValidateSet("eastus", "westus", "eastus2")]
    [string]$location,
[Parameter(Mandatory=$True, Position=7)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
[ValidateLength(1,26)]
[ValidatePattern("[a-z]*")]
    [string]$defaultStorageAccountName,
# Get information for the HDInsight cluster
[Parameter(Mandatory=$True, Position=8)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
    [string]$clusterName,
[Parameter(Mandatory=$True, Position=9)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
    [string]$httpusername = "admin",
[Parameter(Mandatory=$True, Position=10)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
    [string]$sshusername = "cortana" ,
# Default cluster size (# of worker nodes), version, type, and OS
[Parameter(Mandatory=$True, Position=11)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
    [int]$clusterSizeInNodes = 4,
[Parameter(Mandatory=$True, Position=12)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
    [string]$clusterVersion = "3.5",
[Parameter(Mandatory=$True, Position=13)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
    [string]$clusterType = "Hadoop",
[Parameter(Mandatory=$True, Position=14)]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
[ValidateSet("Linux", "Windows")]
    [string]$clusterOS = "Linux"
)


$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $vnetrg -Name $vnetname
$subnet = $vnet.Subnets | where { $_.name -eq $subnetname }
Select-AzureRmSubscription -SubscriptionId $subscriptionID
# Create the resource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location


# Create an Azure storae account and container
New-AzureRmStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $defaultStorageAccountName `
    -Type Standard_LRS `
    -Location $location
$defaultStorageAccountKey = (Get-AzureRmStorageAccountKey `
                                -ResourceGroupName $resourceGroupName `
                                -Name $defaultStorageAccountName)[0].Value
$defaultStorageContext = New-AzureStorageContext `
                                -StorageAccountName $defaultStorageAccountName `
                                -StorageAccountKey $defaultStorageAccountKey

# Cluster login is used to secure HTTPS services hosted on the cluster
$httpsecpasswd = ConvertTo-SecureString “Symantec@123” -AsPlainText -Force
$sshsecpassword = ConvertTo-SecureString “Symantec@123” -AsPlainText -Force

# HTTP user is used to remotely connect to the cluster using SSH clients
$httpCredential =  New-Object System.Management.Automation.PSCredential ($httpusername, $httpsecpasswd)

# SSH user is used to remotely connect to the cluster using SSH clients
$sshCredentials = New-Object System.Management.Automation.PSCredential ($sshusername, $sshsecpasswd)

# Set the storage container name to the cluster name
$defaultBlobContainerName = $clusterName

# Create a blob container. This holds the default data store for the cluster.
New-AzureStorageContainer -Name $clusterName -Context $defaultStorageContext 

# Create the HDInsight cluster
New-AzureRmHDInsightCluster `
    -ResourceGroupName $resourceGroupName `
    -ClusterName $clusterName `
    -Location $location `
    -ClusterSizeInNodes $clusterSizeInNodes `
    -ClusterType $clusterType `
    -OSType $clusterOS `
    -Version $clusterVersion `
    -HttpCredential $httpCredential `
    -DefaultStorageAccountName "$defaultStorageAccountName.blob.core.windows.net" `
    -DefaultStorageAccountKey $defaultStorageAccountKey `
    -DefaultStorageContainer $clusterName `
    -SshCredential $sshCredentials `
    -VirtualNetworkId $vnet.id `
    -SubnetName $subnet.id
    