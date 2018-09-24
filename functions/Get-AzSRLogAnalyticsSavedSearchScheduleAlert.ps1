<#
.SYNOPSIS
    Return the Alerts of a Log Analytics Saved Search Schedule from a Log Analytics Workspace

.DESCRIPTION
    Return the Alerts of a Log Analytics Saved Search Schedule from a Log Analytics Workspace

.PARAMETER SearchId
    The Azure Resource Id of the Log Analytics Search Schedule. Use Get-AzureRmOperationalInsightsWorkspace and Get-AzSRLogAnalyticsSavedSearchList to retrieve this information

.EXAMPLE
    Get-AzureRmOperationalInsightsWorkspace | Get-AzSRLogAnalyticsSavedSearchList | Get-AzSRLogAnalyticsSavedSearchSchedule | Get-AzSRLogAnalyticsSavedSearchScheduleAlert

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRLogAnalyticsSavedSearchScheduleAlert {
    [CmdletBinding()]
    param (
        [Alias('Id')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                if ($_ -match "subscriptions\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/resourcegroups\/[\w\d-]+\/providers\/microsoft.operationalinsights\/workspaces\/[\w\d-]+\/savedSearches\/[\w|()-]+\/schedules/[\w|()-]+$" ) {
                    $true
                } else {
                    throw "Not a valid 'microsoft.operationalinsights/savedSearches' workspace URI"
                }
            }
        )]
        [string]$SearchScheduleId
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
    
        $uri = "https://management.azure.com/$SearchScheduleId/actions?api-version=2015-03-20"

        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
            Verbose     = $False
        }

        $Response = Invoke-RestMethod @params

        Return $Response.value | ForEach-Object {
            New-Object psobject -Property @{
                'id'                 = $_.name
                'etag'               = [datetime]([uri]::UnescapeDataString(($_.etag -replace "^.*'(.*)'.*$", '$1')))
                'Type'               = $_.properties.Type
                'Name'               = $_.properties.Name
                'Description'        = $_.properties.Description
                'Severity'           = $_.properties.Severity
                'Threshold'          = "$($_.properties.Threshold.Operator) $($_.properties.Threshold.Value)".Trim()
                'MetricsTrigger'     = "$($_.properties.Threshold.MetricsTrigger.TriggerCondition) $($_.properties.Threshold.MetricsTrigger.Operator) $($_.properties.Threshold.MetricsTrigger.Value)".Trim()
                'Throttling'         = $_.properties.Throttling.DurationInMinutes
                'GroupIds'           = $_.properties.AzNsNotification.GroupIds
                'CustomEmailSubject' = $_.properties.AzNsNotification.CustomEmailSubject
            }
        }
    }
}
