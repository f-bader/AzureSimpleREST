<#
.SYNOPSIS
    Checks if a given VM is protected by Azure Backup

.DESCRIPTION

    You need contributor rights on the subscription or use a custom role as described here
    https://cloudbrothers.info/reverse-engineering-der-azure-rest-api/

.PARAMETER ResourceId
    The Resource Id of the VM

.EXAMPLE
    Get-AzSRVMByName -SubscriptionId nnnnnnnn -VMName "vmname" | Get-AzSRVMProtectionStatus

.EXAMPLE
    Get-AzVM | Get-AzSRVMProtectionStatus

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRVMProtectionStatus {
    [CmdletBinding()]
    param (
        [Alias('id')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$ResourceId
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
        try {
            $VMInformation = Get-AzSRVM -ResourceId $ResourceId
        } catch {
            Write-Warning "$($_.Exception.Message)"
            throw
        }
        $SubscriptionId = $VMInformation.ResourceId -replace '\/subscriptions\/(.*)/resourceGroups\/.*', '$1'
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.RecoveryServices/locations/$($VMInformation.location)/backupStatus?api-version=2016-06-01"

        Write-Verbose $uri

        $requestBody = @{
            "resourceId"   = $VMInformation.ResourceId
            "resourceType" = "VM"
        }

        $params = @{
            ContentType = 'application/json'
            Headers     = $LoginHeader
            Method      = 'Post'
            URI         = $uri
            Body        = ($requestBody | ConvertTo-Json -Depth 99 )
            Verbose     = $false
        }

        try {
            $Response = Invoke-RestMethod @params
            if ($Response -ne 'null') {
                New-Object psobject -Property @{
                    'protectionStatus'  = $Response.protectionStatus
                    'vaultId'           = $Response.vaultId
                    'fabricName'        = $Response.fabricName
                    'containerName'     = $Response.containerName
                    'protectedItemName' = $Response.protectedItemName
                    'policyName'        = $Response.policyName
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
    End {

    }
}