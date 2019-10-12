<#
.SYNOPSIS
    Get all Recovery Points for a given Protected Item

.DESCRIPTION
    Get all Recovery Points for a given Protected Item

.PARAMETER ProtectedItemId
    Azure Resource id of the protected item

.EXAMPLE
    Get-AzSRSubscription | Get-AzSRRecoveryServiceVault | Get-AzSRRecoveryServiceVaultProtectedItem | Get-AzSRRecoveryServiceVaultProtectedItemRecoveryPoint

.EXAMPLE
    Get-AzSRVMByName -SubscriptionId nnnnnnnn -VMName "vmname" | Get-AzSRVMProtectionStatus | Get-AzSRRecoveryServiceVaultProtectedItemRecoveryPoint

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRRecoveryServiceVaultProtectedItemRecoveryPoint {
    [CmdletBinding()]
    param (
        [Alias('Id')]
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ResourceIdBased',
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
        [string]$ProtectedItemId,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'ValueBased',
            ValueFromPipelineByPropertyName = $true)]
        [string]$protectedItemName,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'ValueBased',
            ValueFromPipelineByPropertyName = $true)]
        [string]$fabricName,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'ValueBased',
            ValueFromPipelineByPropertyName = $true)]
        [string]$containerName,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'ValueBased',
            ValueFromPipelineByPropertyName = $true)]
        [string]$vaultId
    )
    # Query Recovery Points for protected Items
    # https://docs.microsoft.com/en-us/rest/api/backup/recoverypoints/list

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
        $suffixURI = "/recoveryPoints?api-version=2019-05-13&`$filter=restorePointQueryType eq 'rpTypeAll'"
        #endregion
    }

    Process {
        if ($PSCmdlet.ParameterSetName -eq "ValueBased") {
            $ProtectedItemId = $vaultId + "/backupFabrics/" + $fabricName + "/protectionContainers/" +  $containerName  + "/protectedItems/" + $protectedItemName
        }
        $uri = $baseURI + $ProtectedItemId + $suffixURI

        Write-Verbose $uri

        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
            Verbose     = $false
        }
        try {
            $Response = Invoke-RestMethod @params
            $Response.value | ForEach-Object {
                $vmResourceGroup = $ProtectedItemId -replace '.*protectedItems/VM;(.*);(.*);(.*)', '$2'
                $vmName = $ProtectedItemId -replace '.*protectedItems/VM;(.*);(.*);(.*)', '$3'
                New-Object psobject -Property @{
                    'id'                           = $_.id
                    'vmResourceGroup'              = $vmResourceGroup
                    'vmName'                       = $vmName
                    'objectType'                   = $_.properties.objectType
                    'recoveryPointType'            = $_.properties.recoveryPointType
                    'recoveryPointTime'            = $_.properties.recoveryPointTime
                    'sourceVMStorageType'          = $_.properties.sourceVMStorageType
                    'isSourceVMEncrypted'          = $_.properties.isSourceVMEncrypted
                    'isManagedVirtualMachine'      = $_.properties.isManagedVirtualMachine
                    'virtualMachineSize'           = $_.properties.virtualMachineSize
                    'originalStorageAccountOption' = $_.properties.originalStorageAccountOption
                    'osType'                       = $_.properties.osType
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