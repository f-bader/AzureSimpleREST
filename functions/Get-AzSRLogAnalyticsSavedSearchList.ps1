<#
.SYNOPSIS
    Return all Log Analytics Saved Searches from a Log Analytics Workspace

.DESCRIPTION
    Return all Log Analytics Saved Searches from a Log Analytics Workspace

.PARAMETER LogAnalyticsResourceId
    The Azure Resource Id of the Log Analytics Workspace. Use Get-AzureRmOperationalInsightsWorkspace to retrieve this information

.EXAMPLE
    Get-AzureRmOperationalInsightsWorkspace | Get-AzSRLogAnalyticsSavedSearchList

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRLogAnalyticsSavedSearchList {
    [CmdletBinding()]
    param (
        [Alias('ResourceId')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                if ($_ -match "subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourcegroups/[\w\d-]+/providers/microsoft.operationalinsights/workspaces/[\w\d-]+$" ) {
                    $true
                } else {
                    throw "Not a valid 'microsoft.operationalinsights' workspace URI"
                }
            }
        )]
        [string]$LogAnalyticsResourceId
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
        $uri = "https://management.azure.com/$LogAnalyticsResourceId/savedsearches?api-version=2015-03-20"

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
