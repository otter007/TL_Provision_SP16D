#
# Phase3.ps1
#
# Set up key variables
$subscrName="<name of your Azure subscription>"
$rgName="<your resource group name>"
$locName="<the Azure location of your resource group>"
$dnsName="<unique, public domain name label for the SharePoint server>"

# Set the Azure subscription
Get-AzureRmSubscription -SubscriptionName $subscrName | Select-AzureRmSubscription

# Get the Azure storage account name
$sa=Get-AzureRMStorageaccount | where {$_.ResourceGroupName -eq $rgName}
$saName=$sa.StorageAccountName

# Create an availability set for SharePoint virtual machines
New-AzureRMAvailabilitySet -Name spAvailabilitySet -ResourceGroupName $rgName -Location $locName

# Specify the virtual machine name and size
$vmName="spVM"
$vmSize="Standard_D3_V2"
$vm=New-AzureRMVMConfig -VMName $vmName -VMSize $vmSize

# Create the NIC for the virtual machine
$nicName=$vmName + "-NIC"
$pipName=$vmName + "-PublicIP"
$pip=New-AzureRMPublicIpAddress -Name $pipName -ResourceGroupName $rgName -DomainNameLabel $dnsName -Location $locName -AllocationMethod Dynamic
$vnet=Get-AzureRMVirtualNetwork -Name "SP2016Vnet" -ResourceGroupName $rgName
$nic=New-AzureRMNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -PrivateIpAddress "10.0.0.6"
$avSet=Get-AzureRMAvailabilitySet -Name spAvailabilitySet -ResourceGroupName $rgName 
$vm=New-AzureRMVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avSet.Id

# Specify the image and local administrator account, and then add the NIC
$pubName="MicrosoftSharePoint"
$offerName="MicrosoftSharePointServer"
$skuName="2016"
$cred=Get-Credential -Message "Type the name and password of the local administrator account."
$vm=Set-AzureRMVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRMVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"
$vm=Add-AzureRMVMNetworkInterface -VM $vm -Id $nic.Id

# Specify the OS disk name and create the VM
$diskName="OSDisk"
$storageAcc=Get-AzureRMStorageAccount -ResourceGroupName $rgName -Name $saName
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
$vm=Set-AzureRMVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage
New-AzureRMVM -ResourceGroupName $rgName -Location $locName -VM $vm
