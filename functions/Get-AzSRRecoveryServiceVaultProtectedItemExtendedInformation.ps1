<#
.SYNOPSIS
    Get extended information about a Recovery Service Vault protected item

.DESCRIPTION
    Get extended information about a Recovery Service Vault protected item

    Extended information contains:
    * oldestRecoveryPoint
    * RecoveryPointCount
    * policyInconsistent

.PARAMETER ProtectedItemId
    Azure Resource id of the protected item

.EXAMPLE
    Get-AzSRSubscription | Get-AzSRRecoveryServiceVault | Get-AzSRRecoveryServiceVaultProtectedItem | Get-AzSRRecoveryServiceVaultProtectedItemExtendedInformation

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRRecoveryServiceVaultProtectedItemExtendedInformation {
    param (
        [Alias('Id')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                if ($_ -match "subscriptions\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/resourcegroups\/[\w\d-\.]+\/providers\/microsoft\.RecoveryServices\/vaults\/[\w|()-;\/]+\/backupFabrics\/[\w|()-\/;]+\/protectedItems\/[\w|()-\/;]+$" ) {
                    $true
                } else {
                    throw "Not a valid 'microsoft.RecoveryServices/vaults' URI"
                }
            }
        )]
        [string]$ProtectedItemId
    )
    # Query Extended information for protected Items
    # https://docs.microsoft.com/en-us/rest/api/backup/protecteditems/get
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

        #region uri definition
        $baseURI = "https://management.azure.com"
        $suffixURI = "?`$filter=expand+eq+'ExtendedInfo'&api-version=2017-07-01"
        #endregion
    }
    Process {
        $uri = $baseURI + $ProtectedItemId + $suffixURI

        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
            Verbose     = $false
        }

        try {
            $Response = Invoke-RestMethod @params

            $Response | ForEach-Object {
                $vmResourceGroup = $_.properties.sourceResourceId -replace '.*resourceGroups/(.*)/providers.*', '$1'
                $vmName = $_.properties.sourceResourceId -replace '.*/virtualMachines/(.*)', '$1'
                if ($_.properties.lastBackupTime) {
                    $lastBackupTime = ( Get-Date -Date $_.properties.lastBackupTime )
                } else {
                    $lastBackupTime = "n/a"
                }
                if ($_.properties.lastRecoveryPoint) {
                    $lastRecoveryPoint = ( Get-Date -Date $_.properties.lastRecoveryPoint )
                } else {
                    $lastRecoveryPoint = "n/a"
                }
                if ($_.properties.extendedInfo.oldestRecoveryPoint) {
                    $oldestRecoveryPoint = ( Get-Date -Date $_.properties.extendedInfo.oldestRecoveryPoint )
                } else {
                    $oldestRecoveryPoint = "n/a"
                }
                if ($_.properties.extendedInfo.recoveryPointCount) {
                    $RecoveryPointCount = $_.properties.extendedInfo.recoveryPointCount
                } else {
                    $RecoveryPointCount = 0
                }
                New-Object psobject -Property @{
                    'id'                   = $_.id
                    'vmResourceGroup'      = $vmResourceGroup
                    'vmName'               = $vmName
                    'type'                 = $_.type
                    'friendlyName'         = $_.properties.friendlyName
                    'virtualMachineId'     = $_.properties.virtualMachineId
                    'protectionStatus'     = $_.properties.protectionStatus
                    'protectionState'      = $_.properties.protectionState
                    'healthStatus'         = $_.properties.healthStatus
                    'healthMessage'        = $_.properties.healthDetails.message
                    'lastBackupStatus'     = $_.properties.lastBackupStatus
                    'lastBackupTime'       = $lastBackupTime
                    'protectedItemDataId'  = $_.properties.protectedItemDataId
                    'oldestRecoveryPoint'  = $oldestRecoveryPoint
                    'recoveryPointCount'   = $RecoveryPointCount
                    'policyInconsistent'   = $_.properties.extendedInfo.policyInconsistent
                    'protectedItemType'    = $_.properties.protectedItemType
                    'backupManagementType' = $_.properties.backupManagementType
                    'workloadType'         = $_.properties.workloadType
                    'sourceResourceId'     = $_.properties.sourceResourceId
                    'policyId'             = $_.properties.policyId
                    'policyName'           = $_.properties.policyName
                    'lastRecoveryPoint'    = $lastRecoveryPoint
                }
            }
        } catch {
            if ($_.ErrorDetails) {
                Write-Warning "$(($_.ErrorDetails.Message | ConvertFrom-Json).error.message)"
            } else {
                Write-Warning "$($_.Exception.Message)"

            }
        }
    }
}
