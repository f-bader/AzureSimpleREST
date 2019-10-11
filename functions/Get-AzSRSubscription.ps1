<#
.SYNOPSIS
    Gets all subscriptions for a tenant.

.DESCRIPTION
    Gets all subscriptions for a tenant.

    https://docs.microsoft.com/en-us/rest/api/resources/subscriptions/list

.EXAMPLE
    $Subscriptions = Get-AzSRSubscription

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRSubscription {
    [CmdletBinding()]
    param (

    )

    Begin {
        #region Get AccessToken
        try {
            $AccessToken = Get-AzCachedAccessToken
            $LoginHeader = @{
                'authorization' = "Bearer $AccessToken"
            }
        } catch {
            throw $($_.Exception.Message)
        }
        #endregion
    }

    Process {
        $uri = 'https://management.azure.com/subscriptions?api-version=2018-05-01&`$expand=inherited'
        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
            Verbose     = $false
        }

        $Response = Invoke-RestMethod @params
        $Response.value | ForEach-Object {
            Return New-Object psobject -Property @{
                "id"                  = $_.id
                "subscriptionId"      = $_.subscriptionId
                "displayName"         = $_.displayName
                "state"               = $_.state
                "locationPlacementId" = $_.subscriptionPolicies.locationPlacementId
                "quotaId"             = $_.subscriptionPolicies.quotaId
                "spendingLimit"       = $_.subscriptionPolicies.spendingLimit
                "authorizationSource" = $_.authorizationSource
            }
        }
    }
    End {

    }
}
