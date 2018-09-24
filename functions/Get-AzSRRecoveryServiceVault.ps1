<#
.SYNOPSIS
    Get all Azure Recovery Service Vaults

.DESCRIPTION
    Get all Azure Recovery Service Vaults

.PARAMETER SubscriptionID
    The SubscriptionId of the target subscription

.EXAMPLE
    Get-AzSRSubscription | Get-AzSRRecoveryServiceVault

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRRecoveryServiceVault {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript( 
            {
                try {
                    [System.Guid]::Parse($_) | Out-Null
                    $true
                } catch {
                    $false
                }
            }
        )]
        [string]$SubscriptionID
    )
    Begin {
        #region Get AccessToken
        try {
            $AccessToken = Get-AzureRmCachedAccessToken
            $LoginHeader = @{
                'authorization' = "Bearer $AccessToken"
            }
        } catch {
            throw $($_.Exception.Message)
        }
        #endregion
    }
    Process {
        $baseURI = "https://management.azure.com"
        $suffixURI = "/providers/Microsoft.RecoveryServices/vaults?api-version=2016-06-01"
        $uri = $baseURI + "/subscriptions/$SubscriptionID" + $suffixURI

        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
        }

        $Response = Invoke-RestMethod @params
        $Response.value | ForEach-Object {
            New-Object psobject -Property @{
                "location"          = $_.location
                "name"              = $_.name
                "id"                = $_.id
                "type"              = $_.type
                "skuName"           = $_.sku.Name
                "skuTier"           = $_.sku.Tier
                "ResourceGroupName" = $_.id -replace '^.*resourceGroups.(.*).providers.*$', '$1'
            }
        }
    }
}