<#
.SYNOPSIS
    Retreive the detailed information about a backup job

.DESCRIPTION
    Retreive the detailed information about a backup job

.PARAMETER BackupJobId
    Full Azure Resource Id of the Backup Job

.EXAMPLE
    Get-AzSRSubscription | Get-AzSRRecoveryServiceVault | Get-AzSRRecoveryServiceBackupJobs | Get-AzSRRecoveryServiceBackupJobDetails

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRRecoveryServiceBackupJobDetails {
    [CmdletBinding()]
    param (
        [Alias('Id')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                if ($_ -match "subscriptions\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/resourcegroups\/[\w\d-\.]+\/providers\/Microsoft.RecoveryServices\/vaults\/[\w\d-]+\/backupJobs\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$" ) {
                    $true
                } else {
                    throw "Not a valid 'Microsoft.RecoveryServices' Vault URI"
                }
            }
        )]
        [string]$BackupJobId
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
        $suffixURI = '?api-version=2017-07-01'
        $uri = $baseURI + $BackupJobId + $suffixURI

        $BackupJobsList.value  | ForEach-Object {
            #region Get detailed result
            # https://docs.microsoft.com/en-us/rest/api/backup/jobdetails/get

            $params = @{
                ContentType = 'application/x-www-form-urlencoded'
                Headers     = $LoginHeader
                Method      = 'Get'
                URI         = $uri
                Verbose     = $false
            }

            $Response = Invoke-RestMethod @params
            if ($Response -ne 'null') {
                if ($Response.properties.duration) {
                    $Duration = (Convert-ISO8601ToTimespan -Duration $Response.properties.duration)
                } else {
                    $Duration = $null
                }
                if ($Response.properties.startTime) {
                    $startTime = (Get-Date $Response.properties.startTime)
                } else {
                    $startTime = $null
                }
                New-Object psobject -Property @{
                    "id"                    = $Response.id
                    "name"                  = $Response.name
                    "type"                  = $Response.type
                    "jobType"               = $Response.properties.jobType
                    "duration"              = $Duration
                    "actionsInfo"           = $Response.properties.actionsInfo
                    "virtualMachineVersion" = $Response.properties.virtualMachineVersion
                    "tasksList"             = $Response.properties.extendedInfo.tasksList
                    "jobInternalProperties" = $Response.properties.extendedInfo.internalPropertyBag
                    "jobProperties"         = $Response.properties.extendedInfo.propertyBag
                    "entityFriendlyName"    = $Response.properties.entityFriendlyName
                    "backupManagementType"  = $Response.properties.backupManagementType
                    "operation"             = $Response.properties.operation
                    "status"                = $Response.properties.status
                    "startTime"             = $startTime
                    "activityId"            = $Response.properties.activityId
                }
            }
        }
    }
}