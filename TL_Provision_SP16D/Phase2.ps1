#
# Phase2.ps1
#
# Log in to Azure
Login-AzureRmAccount

# Set up key variables
$subscrName="<name of your Azure subscription>"
$rgName="<your resource group name>"
$locName="<the Azure location of your resource group>"
$dnsName="<unique, public domain name label for the SQL server>"

# Set the Azure subscription
Get-AzureRmSubscription -SubscriptionName $subscrName | Select-AzureRmSubscription

# Get the Azure storage account name
$sa=Get-AzureRMStorageaccount | where {$_.ResourceGroupName -eq $rgName}
$saName=$sa.StorageAccountName

# Create an availability set for SQL Server virtual machines
New-AzureRMAvailabilitySet -Name sqlAvailabilitySet -ResourceGroupName $rgName -Location $locName

# Create the SQL Server virtual machine
$vmName="sqlVM"
$vmSize="Standard_D3_V2"
$vnet=Get-AzureRMVirtualNetwork -Name "SP2016Vnet" -ResourceGroupName $rgName

$nicName=$vmName + "-NIC"
$pipName=$vmName + "-PublicIP"
$pip=New-AzureRMPublicIpAddress -Name $pipName -ResourceGroupName $rgName -DomainNameLabel $dnsName -Location $locName -AllocationMethod Dynamic
$nic=New-AzureRMNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -PrivateIpAddress "10.0.0.5"
$avSet=Get-AzureRMAvailabilitySet -Name sqlAvailabilitySet -ResourceGroupName $rgName 
$vm=New-AzureRMVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avSet.Id

$diskSize=100
$diskLabel="SQLData"
$storageAcc=Get-AzureRMStorageAccount -ResourceGroupName $rgName -Name $saName
$vhdURI=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + "-SQLDataDisk.vhd"
Add-AzureRMVMDataDisk -VM $vm -Name $diskLabel -DiskSizeInGB $diskSize -VhdUri $vhdURI  -CreateOption empty

$cred=Get-Credential -Message "Type the name and password of the local administrator account of the SQL Server computer." 
$vm=Set-AzureRMVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRMVMSourceImage -VM $vm -PublisherName MicrosoftSQLServer -Offer SQL2014SP1-WS2012R2 -Skus Standard -Version "latest"
$vm=Add-AzureRMVMNetworkInterface -VM $vm -Id $nic.Id
$storageAcc=Get-AzureRMStorageAccount -ResourceGroupName $rgName -Name $saName
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + "-OSDisk.vhd"
$vm=Set-AzureRMVMOSDisk -VM $vm -Name "OSDisk" -VhdUri $osDiskUri -CreateOption fromImage
New-AzureRMVM -ResourceGroupName $rgName -Location $locName -VM $vm


#Connect to the SQL Server virtual machine (sqlVM) using the credentials of the local administrator account.
#Next, join the SQL Server to the Windows Server AD domain with these commands at a Windows PowerShell prompt.

Add-Computer -DomainName "corp.contoso.com"
Restart-Computer
