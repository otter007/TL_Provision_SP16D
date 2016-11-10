 #
# Script.ps1
## Reference https://technet.microsoft.com/library/mt723354.aspx
##Checking if Azure Powershell is installed on the computer
$name = 'Azure'

Write-Output "Checking if Azure Powershell is installed"
if(Get-Module -ListAvailable | Where-Object{$_.Name -eq $name})
{
	(Get-Module -ListAvailable | Where-Object{$_.Name -eq $name}) |
	Select Version, Name, Author, PowershellVersion | Format-List;
	Write-Output "Azure Powershell is installed."
}
else
{
	#Provide the link to install Azure Powershell, if not installed
	Write-Warning "Please install Azure Powershell.  To install Azure Powershell go to http://bit.ly/AnurePowershellDownload"
	Exit 1
}



# PrepWork
# login with your Azure account
# Not useing Get-Credentials because that will force me to use the Organization ID Credentials
# $Credential = Get-Credential
# Login-AzureRMAccount -Credential $Credential
Read-Host -Prompt "Make sure you are logged into Azure"
Login-AzureRMAccount


# Find out what the subsciption name is for your tenent - Pick the one you want
Get-AzureRMSubscription | Sort SubscriptionName | Select SubscriptionName

$subscr="Visual Studio Ultimate with MSDN"
Get-AzureRmSubscription –SubscriptionName $subscr | Select-AzureRmSubscription


# Get the names of you currently existing RGroup Names
Get-AzureRMResourceGroup | Sort ResourceGroupName | Select ResourceGroupName

##Prompt user for name that should be used for the resource group.  
#$rgName= Read-Host "Please enter the <resource group name>"
#Write-Host "The resource group will default to East US location"
#$locName="East US"
#$locShortName="eastus"
##Create the new Resource Group
#try {
#	New-AzureRMResourceGroup -Name $rgName -Location $locName -Tag @( @{ Name="Type"; Value="Personal" }, @{ Name="Env"; Value="Dev"}) 
#}
#catch{
#	Write-Warning -message 'There is was a problem creating the Resource Group.' -WarningAction Stop
#}


Get-AzureRMStorageAccount | Sort StorageAccountName | Select StorageAccountName

$rgName="<your new resource group name>"
$locName="<the location of your new resource group>"
$saName="<storage account name>"
New-AzureRMStorageAccount -Name $saName -ResourceGroupName $rgName -Type Standard_LRS -Location $locName

$rgName="<name of your new resource group>"
$locName="<Azure location name, such as West US>"
$locShortName="<the location of your new resource group in lowercase with spaces removed, example: westus>"
$spSubnet=New-AzureRMVirtualNetworkSubnetConfig -Name SP2016Subnet -AddressPrefix 10.0.0.0/24
New-AzureRMVirtualNetwork -Name SP2016Vnet -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $spSubnet -DNSServer 10.0.0.4
$rule1=New-AzureRMNetworkSecurityRuleConfig -Name "RDPTraffic" -Description "Allow RDP to all VMs on the subnet" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
$rule2 = New-AzureRMNetworkSecurityRuleConfig -Name "WebTraffic" -Description "Allow HTTP to the SharePoint server" -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix "10.0.0.6/32" -DestinationPortRange 80
New-AzureRMNetworkSecurityGroup -Name SP2016Subnet -ResourceGroupName $rgName -Location $locShortName -SecurityRules $rule1, $rule2
$vnet=Get-AzureRMVirtualNetwork -ResourceGroupName $rgName -Name SP2016Vnet
$nsg=Get-AzureRMNetworkSecurityGroup -Name SP2016Subnet -ResourceGroupName $rgName
Set-AzureRMVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name SP2016Subnet -AddressPrefix "10.0.0.0/24" -NetworkSecurityGroup $nsg

$rgName="<resource group name>"
$locName="<Azure location, such as West US>"

# Get the Azure storage account name
$sa=Get-AzureRMStorageaccount | where {$_.ResourceGroupName -eq $rgName}
$saName=$sa.StorageAccountName

# Create an availability set for domain controller virtual machines
New-AzureRMAvailabilitySet -Name dcAvailabilitySet -ResourceGroupName $rgName -Location $locName

# Create the domain controller virtual machine
$vnet=Get-AzureRMVirtualNetwork -Name SP2016Vnet -ResourceGroupName $rgName
$pip = New-AzureRMPublicIpAddress -Name adVM-NIC -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic
$nic = New-AzureRMNetworkInterface -Name adVM-NIC -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -PrivateIpAddress 10.0.0.4

$avSet=Get-AzureRMAvailabilitySet -Name dcAvailabilitySet -ResourceGroupName $rgName 
$vm=New-AzureRMVMConfig -VMName adVM -VMSize Standard_D1_v2 -AvailabilitySetId $avSet.Id

$storageAcc=Get-AzureRMStorageAccount -ResourceGroupName $rgName -Name $saName
$vhdURI=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/adVM-SP2016Vnet-ADDSDisk.vhd"
Add-AzureRMVMDataDisk -VM $vm -Name ADDS-Data -DiskSizeInGB 20 -VhdUri $vhdURI  -CreateOption empty
$cred=Get-Credential -Message "Type the name and password of the local administrator account for adVM."

$vm=Set-AzureRMVMOperatingSystem -VM $vm -Windows -ComputerName adVM -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AzureRMVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
$vm=Add-AzureRMVMNetworkInterface -VM $vm -Id $nic.Id
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/adVM-SP2016Vnet-OSDisk.vhd"
$vm=Set-AzureRMVMOSDisk -VM $vm -Name adVM-SP2016Vnet-OSDisk -VhdUri $osDiskUri -CreateOption fromImage
New-AzureRMVM -ResourceGroupName $rgName -Location $locName -VM $vm

Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName corp.contoso.com -DatabasePath "F:\NTDS" -SysvolPath "F:\SYSVOL" -LogPath "F:\Logs"

Add-WindowsFeature RSAT-ADDS-Tools
New-ADUser -SamAccountName sp_farm_db -AccountPassword (read-host "Set user password" -assecurestring) -name "sp_farm_db" -enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false

