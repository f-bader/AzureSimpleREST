<#
.SYNOPSIS
    Remove a protected item from a Recovery Service Vault

.DESCRIPTION
    Remove a protected item from a Recovery Service Vault

.PARAMETER ProtectedItemId
    Azure Resource id of the protected item

.PARAMETER Async
    Do not wait until the Protected Item was deleted. Wait time is minium 60 seconds to honor 'Retry-After' HTTP Response

.PARAMETER Force
    Delete Protected Item even if there are still valid Recovery Points

.EXAMPLE
    Get-AzSRSubscription | Get-AzSRRecoveryServiceVault | Get-AzSRRecoveryServiceVaultProtectedItems | Remove-AzSRRecoveryServiceVaultProtectedItem

    Removes every Protected item when no Recovery Points are available.

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Remove-AzSRRecoveryServiceVaultProtectedItem {
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [Alias('Id')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                if ($_ -match "subscriptions\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/resourcegroups\/[\w\d-]+\/providers\/microsoft\.RecoveryServices\/vaults\/[\w|()-;\/]+\/backupFabrics\/[\w|()-\/;]+\/protectedItems\/[\w|()-\/;]+$" ) {
                    $true
                } else {
                    throw "Not a valid 'microsoft.RecoveryServices/vaults' URI"
                }
            }
        )]
        [string]$ProtectedItemId,
        [switch]$Async,
        [switch]$Force
    )
    # Delete a Backup Protected Item
    # https://docs.microsoft.com/en-us/rest/api/backup/protecteditems/delete
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
        $suffixURI = "?api-version=2016-12-01"
        $uri = $baseURI + $ProtectedItemId + $suffixURI

        $params = @{
            Headers         = $LoginHeader
            Method          = 'DELETE'
            URI             = $uri
            Verbose         = $false
            UseBasicParsing = $true
        }

        # Retrieve extended information about the Protected Item
        $ProtectedItem = Get-AzSRRecoveryServiceVaultProtectedItemExtendedInformation -ProtectedItemId $ProtectedItemId
        if ($ProtectedItem) {
            # Only delete the Protected Item if there are no more recoveryPoints
            if ($Force.IsPresent -or $ProtectedItem.recoveryPointCount -eq 0 ) {
                if ($PSCmdlet.ShouldProcess("Delete protected item for VM `"$($ProtectedItem.vmName)`" in Resource Group `"$($ProtectedItem.vmResourceGroup)`"")) {
                    try {
                        $Response = Invoke-WebRequest @params
                        if ( $Response.StatusCode -eq 202) {
                            Write-Verbose "Delete request was accepted."
                            if ( -not $Async.IsPresent ) {
                                # Query status until not 'InProgress' if ASync is not present
                                do {
                                    Start-Sleep -Seconds $Response.Headers.'Retry-After'
                                    $params = @{
                                        Headers = $LoginHeader
                                        Method  = 'GET'
                                        URI     = $Response.Headers.'Azure-AsyncOperation'
                                        Verbose = $false
                                    }
                                    $ASyncResponse = Invoke-RestMethod @params
                                } while ($ASyncResponse.status -eq "InProgress")
                                switch ($ASyncResponse.status) {
                                    "Canceled" { throw "Delete operation was canceled." }
                                    "Failed" { throw "Protected item for VM `"$($ProtectedItem.vmName)`" in Resource Group `"$($ProtectedItem.vmResourceGroup)`" could not be deleted" }
                                    "Invalid" { throw "Invalid request" }
                                    "Succeeded" {
                                        Write-Information "Protected item for VM `"$($ProtectedItem.vmName)`" in Resource Group `"$($ProtectedItem.vmResourceGroup)`" was successfully deleted"
                                    }
                                    Default {}
                                }
                            } else {
                                Write-Verbose "Azure-AsyncOperation: $($Response.Headers.'Azure-AsyncOperation')"
                            }
                        } else {
                            throw "Request was not accepted. No content provided"
                        }
                    } catch {
                        if ($_.ErrorDetails) {
                            Write-Warning "$(($_.ErrorDetails.Message | ConvertFrom-Json).error.message)"
                        } else {
                            Write-Warning "$($_.Exception.Message)"
     
                        }
                    }
                }
            } else {
                Write-Warning "Protected item for VM `"$($ProtectedItem.vmName)`" in Resource Group `"$($ProtectedItem.vmResourceGroup)`" still has $($ProtectedItem.recoveryPointCount) Recovery Points. Use Force parameter to delete it anyways."
            }
        }
    }
}