<#
.SYNOPSIS
    Return the configuration of a Log Analytics Saved Searches from a Log Analytics Workspace

.DESCRIPTION
    Return the configuration of a Log Analytics Saved Searches from a Log Analytics Workspace

.PARAMETER SearchId
    The Azure Resource Id of the Log Analytics Search. Use Get-AzureRmOperationalInsightsWorkspace and Get-AzSRLogAnalyticsSavedSearchList to retrieve this information

.EXAMPLE
    Get-AzureRmOperationalInsightsWorkspace | Get-AzSRLogAnalyticsSavedSearchList | Get-AzSRLogAnalyticsSavedSearch

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRLogAnalyticsSavedSearch {
    [CmdletBinding()]
    param (
        [Alias('Id')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                if ($_ -match "subscriptions\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/resourcegroups\/[\w\d-]+\/providers\/microsoft.operationalinsights\/workspaces\/[\w\d-]+\/savedSearches\/[\w|()-]+$" ) {
                    $true
                } else {
                    throw "Not a valid 'microsoft.operationalinsights/savedSearches' workspace URI"
                }
            }
        )]
        [string]$SearchId
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
        $uri = "https://management.azure.com/$SearchId/?api-version=2015-03-20"
        Write-Verbose $uri
        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
            Verbose     = $False
        }

        $Response = Invoke-RestMethod @params
        Return $Response.properties
    }
}
