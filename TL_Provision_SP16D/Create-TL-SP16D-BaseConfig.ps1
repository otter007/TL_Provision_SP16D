 #
# Script.ps1
#
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

#Prompt user for name that should be used for the resource group.  
$rgName= Read-Host "Please enter the <resource group name>"
Write-Host "The resource group will default to East US location"
$locName="East US"
$locShortName="eastus"
#Create the new Resource Group
try {
	New-AzureRMResourceGroup -Name $rgName -Location $locName -Tag @( @{ Name="Type"; Value="Personal" }, @{ Name="Env"; Value="Dev"}) 
}
catch{
	Write-Warning -message 'There is was a problem creating the Resource Group.' -WarningAction Stop
}


