function Get-AzureRmCachedAccessToken() {
    <#
    .SYNOPSIS
        Returns the current Access token from the AzureRM Module. You need to login first with Connect-AzureRmAccount
    
    .DESCRIPTION
        Allows easy retrival of you Azure API Access Token / Bearer Token
        This makes it much easier to use Invoke-RestMethod because you do not need a service principal
    
    .EXAMPLE
        Get-AzureRmCachedAccessToken
    
    .NOTES
        Website: https://gallery.technet.microsoft.com/scriptcenter/Easily-obtain-AccessToken-3ba6e593/view/Discussions#content
        Copyright: (c) 2018 Stéphane Lapointe
        License: MIT https://opensource.org/licenses/MIT
    #>
    $ErrorActionPreference = 'Stop'

    if (-not (Get-Module AzureRm.Profile)) {
        Import-Module AzureRm.Profile
    }
    $azureRmProfileModuleVersion = (Get-Module AzureRm.Profile).Version
    # refactoring performed in AzureRm.Profile v3.0 or later
    if ($azureRmProfileModuleVersion.Major -ge 3) {
        $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
        if (-not $azureRmProfile.Accounts.Count) {
            Write-Error "Ensure you have logged in (Connect-AzureRmAccount) before calling this function."
        }
    } else {
        # AzureRm.Profile < v3.0
        $azureRmProfile = [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile
        if (-not $azureRmProfile.Context.Account.Count) {
            Write-Error "Ensure you have logged in (Connect-AzureRmAccount) before calling this function."
        }
    }

    $currentAzureContext = Get-AzureRmContext
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile)
    Write-Debug ("Getting access token for tenant" + $currentAzureContext.Subscription.TenantId)
    $token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId)
    $token.AccessToken
}