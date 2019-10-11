function Get-AzCachedAccessToken() {
    <#
    .SYNOPSIS
        Returns the current Access token from the Az Module. You need to login first with Connect-AzAccount

    .DESCRIPTION
        Allows easy retrieval of you Azure API Access Token / Bearer Token
        This makes it much easier to use Invoke-RestMethod because you do not need a service principal

    .EXAMPLE
        Get-AzCachedAccessToken

    .NOTES
        Website: https://gallery.technet.microsoft.com/scriptcenter/Easily-obtain-AccessToken-3ba6e593/view/Discussions#content
        Copyright: (c) 2018 Stéphane Lapointe
        License: MIT https://opensource.org/licenses/MIT
    #>
    $ErrorActionPreference = 'Stop'

    if (-not (Get-Module Az.Accounts)) {
        Import-Module Az.Accounts
    }

    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    if (-not $azProfile.Accounts.Count) {
        Write-Error "Ensure you have logged in (Connect-AzAccount) before calling this function."
    }

    $currentAzureContext = Get-AzContext

    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
    Write-Debug ("Getting access token for tenant" + $currentAzureContext.Subscription.TenantId)
    $token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId)
    $token.AccessToken
}
