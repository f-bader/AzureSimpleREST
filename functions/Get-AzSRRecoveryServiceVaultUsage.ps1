<#
.SYNOPSIS
    Get storage usage of a Recovery Service Vault

.DESCRIPTION
    Get storage usage of a Recovery Service Vault

.PARAMETER VaultId
    Azure Resource Id of the Recovery Service Vault

.EXAMPLE
    Get-AzSRSubscription | Get-AzSRRecoveryServiceVault | Get-AzSRRecoveryServiceVaultUsage

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRRecoveryServiceVaultUsage {
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
                    throw "Not  a valid 'microsoft.RecoveryServices/vaults' URI"
                }
            }
        )]
        [string]$VaultId
    )
    # https://docs.microsoft.com/en-us/rest/api/recoveryservices/usages/listbyvaults
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
        $suffixURI = "/usages?api-version=2016-06-01"
        $uri = $baseURI + $VaultId + $suffixURI

        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
            Verbose     = $false
        }

        $VaultUsageResponse = Invoke-RestMethod @params

        $VaultUsageResponse.value | Where-Object { $_.unit -eq "Bytes" } | ForEach-Object {
            $VaultUsage = New-Object psobject
            $VaultUsage | Add-Member -MemberType NoteProperty -Name "BackupedSizeMB" -Value ([int64]($_.currentValue / 1024 / 1024))
            $VaultUsage | Add-Member -MemberType NoteProperty -Name "Name" -Value $_.name.value
            $VaultUsage | Add-Member -MemberType NoteProperty -Name "localizedName" -Value $_.name.localizedValue
            $VaultUsage | Add-Member -MemberType NoteProperty -Name "VaultId" -Value $VaultId
            $VaultUsage
        }
    }
}