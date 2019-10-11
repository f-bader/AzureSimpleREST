<#
.SYNOPSIS
    A list of all Backup jobs processed on a specifiec Recovery Service Vault

.DESCRIPTION
    A list of all Backup jobs processed on a specifiec Recovery Service Vault

.PARAMETER VaultId
    Azure Resource Id of the Recovery Service Vault

.PARAMETER DaysBack
    How many days back should be queried
    Default: 30 days

.EXAMPLE
    Get-AzSRSubscription | Get-AzSRRecoveryServiceVault | Get-AzSRRecoveryServiceBackupJobs

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRRecoveryServiceBackupJobs {
    [CmdletBinding()]
    param (
        [Alias('Id')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                if ($_ -match "subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourcegroups/[\w\d-]+/providers/Microsoft.RecoveryServices/vaults/[\w\d-]+$" ) {
                    $true
                } else {
                    throw "Not a valid 'Microsoft.RecoveryServices' Vault URI"
                }
            }
        )]
        [string]$VaultId,
        $DaysBack = 30
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

        # https://docs.microsoft.com/en-us/rest/api/backup/backupjobs/list
        $baseURI = "https://management.azure.com"
        $FormatDateUS = 'en-US' -as [Globalization.CultureInfo]
        $FilterFromDate = (Get-Date).AddDays( - $DaysBack).ToUniversalTime().ToString("yyyy-MM-dd hh:mm:ss tt", $FormatDateUS)
        $FilterToDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd hh:mm:ss tt", $FormatDateUS)
        $filter = "startTime eq '$FilterFromDate' and endTime eq '$FilterToDate'"
        $filter = [uri]::EscapeDataString($filter)
        $suffixURI = "/backupJobs?api-version=2017-07-01&`$filter=$filter"
        $uri = $baseURI + $VaultId + $suffixURI

        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
            Verbose     = $false
        }
        Write-Verbose $uri
        $Response = Invoke-RestMethod @params
        if ($Response -ne 'null') {
            if ($_.properties.duration) {
                $Duration = (Convert-ISO8601ToTimespan -Duration $_.properties.duration)
            } else {
                $Duration = $null
            }
            if ($_.properties.startTime) {
                $startTime = (Get-Date $_.properties.startTime)
            } else {
                $startTime = $null
            }
            $Response.value  | ForEach-Object {
                New-Object psobject -Property @{
                    "id"                    = $_.id
                    "name"                  = $_.name
                    "type"                  = $_.type
                    "jobType"               = $_.properties.jobType
                    "duration"              = $Duration
                    "virtualMachineVersion" = $_.properties.virtualMachineVersion
                    "entityFriendlyName"    = $_.properties.entityFriendlyName
                    "backupManagementType"  = $_.properties.backupManagementType
                    "operation"             = $_.properties.operation
                    "status"                = $_.properties.status
                    "startTime"             = $startTime
                    "activityId"            = $_.properties.activityId
                }
            }
        }
    }
}