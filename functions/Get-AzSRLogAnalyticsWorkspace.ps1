<#
.SYNOPSIS
    Get all Log Analytics Workspaces

.DESCRIPTION
    Get all Log Analytics Workspaces

.PARAMETER SubscriptionID
    The SubscriptionId of the target subscription

.EXAMPLE
    Get-AzSRSubscription | Get-AzSRLogAnalyticsWorkspace

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRLogAnalyticsWorkspace {
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
        [string]$SubscriptionId
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
            
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.OperationalInsights/workspaces?api-version=2015-03-20"

        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
            Verbose     = $False
        }

        $Response = Invoke-RestMethod @params
        Return $Response.value
    }
}