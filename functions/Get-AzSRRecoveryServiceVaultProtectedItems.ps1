<#
.SYNOPSIS
    Get all protected items from a Recovery Service Vault

.DESCRIPTION
    Get all protected items from a Recovery Service Vault

.PARAMETER VaultId
    Azure Resource Id of the Recovery Service Vault

.EXAMPLE
    Get-AzSRSubscription | Get-AzSRRecoveryServiceVault | Get-AzSRRecoveryServiceVaultProtectedItems

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRRecoveryServiceVaultProtectedItems {
    [CmdletBinding()]
    param (
        [Alias('Id')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                if ($_ -match "subscriptions\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/resourcegroups\/[\w\d-\.]+\/providers\/microsoft\.RecoveryServices\/vaults\/[\w|()-]+$" ) {
                    $true
                } else {
                    throw "Not a valid 'microsoft.RecoveryServices/vaults' URI"
                }
            }
        )]
        [string]$VaultId
    )
    # Query Backup Protected Items
    # https://docs.microsoft.com/en-us/rest/api/backup/backupprotecteditems/list
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
        $baseURI = "https://management.azure.com"
        $suffixURI = "/backupProtectedItems?api-version=2017-07-01"
        $uri = $baseURI + $VaultId + $suffixURI

        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
            Verbose     = $false
        }

        $Response = Invoke-RestMethod @params
        $Response.value | ForEach-Object {
            New-Object psobject -Property @{
                'id'                   = $_.id
                'VMName'               = $_.properties.friendlyName
                'virtualMachineId'     = $_.properties.virtualMachineId
                'protectionStatus'     = $_.properties.protectionStatus
                'protectedItemType'    = $_.properties.protectedItemType
                'protectionState'      = $_.properties.protectionState
                'healthStatus'         = $_.properties.healthStatus
                'healthDetails'        = $_.properties.healthDetails.message
                'lastBackupStatus'     = $_.properties.lastBackupStatus
                'backupManagementType' = $_.properties.backupManagementType
                'Policy'               = $_.properties.policyName
                'lastRecoveryPoint'    = $_.properties.lastRecoveryPoint
            }
        }
    }
}