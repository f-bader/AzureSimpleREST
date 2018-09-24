<#
.SYNOPSIS
    Return the Schedule of a Log Analytics Saved Search from a Log Analytics Workspace

.DESCRIPTION
    Return the Schedule of a Log Analytics Saved Search from a Log Analytics Workspace

.PARAMETER SearchId
    The Azure Resource Id of the Log Analytics Search. Use Get-AzureRmOperationalInsightsWorkspace and Get-AzSRLogAnalyticsSavedSearchList to retrieve this information

.EXAMPLE
    Get-AzureRmOperationalInsightsWorkspace | Get-AzSRLogAnalyticsSavedSearchList | Get-AzSRLogAnalyticsSavedSearchSchedule

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRLogAnalyticsSavedSearchSchedule {
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

        #$SearchId = [uri]::EscapeDataString($SearchId)
        $uri = "https://management.azure.com/$SearchId/schedules?api-version=2015-03-20"
        Write-Verbose $uri
        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
            Verbose     = $False
        }

        try {
            $Response = Invoke-RestMethod @params
            Return $Response.value | ForEach-Object {
                New-Object psobject -Property @{
                    'id'            = $_.id
                    'etag'          = [datetime]([uri]::UnescapeDataString(($_.etag -replace "^.*'(.*)'.*$", '$1')))
                    'Interval'      = $_.properties.Interval
                    'QueryTimeSpan' = $_.properties.QueryTimeSpan
                    'Enabled'       = $_.properties.Enabled
                    'NearRealTime'  = $_.properties.NearRealTime
                }
            }
        } catch {
            Write-Warning "Could not retrieve the data. $($_.Exception.Message))"
        }
    }
}
