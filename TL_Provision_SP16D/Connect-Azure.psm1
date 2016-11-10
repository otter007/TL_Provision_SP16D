#
# Connect_Azure.psm1
#
# Reference: http://social.technet.microsoft.com/wiki/contents/articles/34515.validate-sharepoint-online-tenant-admin-url-using-powershell-csom.aspx

Import-Module 'C:\Program Files\NuGet\Packages\Microsoft.SharePointOnline.CSOM.16.1.5312.1200\lib\net45\Microsoft.SharePoint.Client.dll'            
Import-Module 'C:\Program Files\NuGet\Packages\Microsoft.SharePointOnline.CSOM.16.1.5312.1200\lib\net45\Microsoft.SharePoint.Client.Runtime.dll'            
Import-Module 'C:\Program Files\NuGet\Packages\Microsoft.SharePointOnline.CSOM.16.1.5312.1200\lib\net45\Microsoft.Online.SharePoint.Client.Tenant.dll'            
function Connect-xSPOTenant {            
    [CmdletBinding()]            
    param(            
        [Parameter(Mandatory)]            
        [uri]            
        $Url,            
                    
        [Parameter(Mandatory)]            
        [System.Management.Automation.CredentialAttribute()]            
        [pscredential]            
        $Credential            
    )            
                
                
        $Script:SPOCredential = [Microsoft.SharePoint.Client.SharePointOnlineCredentials]::new($Credential.UserName , $Credential.Password)            
        $SPOClientContext = [Microsoft.SharePoint.Client.ClientContext]::new($Url)            
        $SPOClientContext.Credentials = $SPOCredential            
        $oTenant = [Microsoft.Online.SharePoint.TenantAdministration.Tenant]::new($SPOClientContext)            
        $oTenant.ServerObjectIsNull.Value -ne $true | Out-Null            
        try {            
            $SPOClientContext.ExecuteQuery()            
        }            
        Catch{            
            $_.Exception.Message             
        }            
            
                 
}            
Connect-xSPOTenant -Url https://contoso.sharepoint.com -Credential "chendrayan@contoso.onmicrosoft
