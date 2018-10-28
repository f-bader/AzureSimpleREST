<#
.SYNOPSIS
    Return the ResourceId of the Automation Account linked to a specific Log Analytics Workspace

.DESCRIPTION
    Return the ResourceId of the Automation Account linked to a specific Log Analytics Workspace

.PARAMETER LogAnalyticsResourceId
    The Azure Resource Id of the Log Analytics Workspace. Use Get-AzureRmOperationalInsightsWorkspace to retrieve this information

.EXAMPLE
    Get-AzureRmOperationalInsightsWorkspace | Get-AzSRLogAnalyticsLinkedAutomationAccount

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRLogAnalyticsLinkedAutomationAccount {
    [CmdletBinding()]
    param (
        [Alias('ResourceId')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                if ($_ -match "subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourcegroups/[\w\d-\.]+/providers/microsoft.operationalinsights/workspaces/[\w\d-]+$" ) {
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
        # https://dev.loganalytics.io/documentation/1-Tutorials/ARM-API
        $uri = "https://management.azure.com/$LogAnalyticsResourceId/LinkedServices/Automation?api-version=2015-11-01-preview"

        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
            Verbose     = $false
        }

        $Response = Invoke-RestMethod @params
        if ($Response -ne 'null') {
            $Response | ForEach-Object {
                New-Object psobject -Property @{
                    resourceId = $_.properties.resourceId
                    id         = $_.id
                    Name       = $_.name
                    Type       = $_.type
                }
            }
        }
    }
}
