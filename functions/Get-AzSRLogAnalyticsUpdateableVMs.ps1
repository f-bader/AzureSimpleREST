<#
.SYNOPSIS
    Returns all virtual machines that can be updated with the Azure Automation Update solution

.DESCRIPTION
    Returns all virtual machines that can be updated with the Azure Automation Update solution
    Only returns virtual machines that have reported back within the last 12 ours and have the Updates solution is enabled

.PARAMETER LogAnalyticsResourceId
    The Azure Resource Id of the Log Analytics Workspace. Use Get-AzureRmOperationalInsightsWorkspace to retrieve this information

.EXAMPLE
    Get-AzureRmOperationalInsightsWorkspace | Get-AzSRLogAnalyticsUpdatableVMs

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRLogAnalyticsUpdateableVMs {
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
        [String]$LogAnalyticsResourceId
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

        # https://dev.loganalytics.io/documentation/1-Tutorials/ARM-API
        $uri = "https://management.azure.com/$LogAnalyticsResourceId/query?api-version=2017-10-01"
        Write-Verbose "$uri"
        $requestBody = @{
            "top"      = 1000000000
            "query"    = 'Heartbeat | where TimeGenerated > ago(12h) and notempty(Computer) and Solutions has "updates" | summarize arg_max(TimeGenerated, Computer, OSType, ComputerEnvironment, ResourceId) by SourceComputerId | sort by Computer asc | project Computer,OSType,ComputerEnvironment,ResourceId'
            "timespan" = "PT12H"
        }

        $params = @{
            ContentType = 'application/json'
            Headers     = $LoginHeader
            Method      = 'Post'
            URI         = $uri
            Body        = ($requestBody | ConvertTo-Json -Depth 99 )
            Verbose     = $false
        }

        $Response = Invoke-RestMethod @params
        if ($Response -ne 'null') {
            if ($Response.tables.rows.Count -gt 0) {
                $Response.tables.rows | ForEach-Object {
                    New-Object psobject -Property @{
                        "Computer"            = $_[0]
                        "OSType"              = $_[1]
                        "ComputerEnvironment" = $_[2]
                        "ResourceId"          = $_[3]
                    }
                }
            }
        }
    }
}
