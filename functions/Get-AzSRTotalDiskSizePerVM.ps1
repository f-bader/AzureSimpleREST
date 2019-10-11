<#
.SYNOPSIS
    Returns a list of all VMs with the sum of managed disk space allocated to them

.DESCRIPTION
    Queries every managed disk within a subscription and returns a grouped list per virtual machine.
    This includes VM name and the total amount of managed disk space this vm has allocated.

.PARAMETER SubscriptionId
    The SubscriptionId of the target subscription

.EXAMPLE
    Get-AzSRTotalDiskSizePerVM -SubscriptionId nnnnnnnn-nnnn-nnnn-nnnn-nnnnnnnnnnn

.EXAMPLE
    Get-AzSRSubscription | Get-AzSRTotalDiskSizePerVM

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>

function Get-AzSRTotalDiskSizePerVM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                try {
                    [System.Guid]::Parse($_) | Out-Null
                    $true
                } catch {
                    $false
                }
            }
        )]
        [string]$SubscriptionId
    )
    #region Get Disks in subscription
    # https://docs.microsoft.com/en-us/rest/api/compute/disks/list

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
        #region Normalize UUID
        $SubscriptionId = [System.Guid]::Parse($SubscriptionId).Guid
        #endregion

        #region Prepare and execute REST method
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Compute/disks?api-version=2017-03-30"

        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
        }

        $Response = Invoke-RestMethod @params
        #endregion

        #region Get information about the disk size (MB) and VM name
        $DisksProperties = $Response.value | ForEach-Object {
            # Ignore disks without a managing VM
            if ($_.managedBy) {
                New-Object psobject -Property @{
                    "diskSizeGB"      = ([int]($_.properties.diskSizeGB))
                    "CostCenter"      = $_.tags.CostCenter
                    "BusinessService" = $_.tags.BusinessService
                    "managedBy"       = $_.managedBy
                    "vmName"          = ($_.managedBy -replace '^.*virtualMachines/' )
                }
            }
        }
        #endregion

        #region Consolidate the data that there is only the sum of disksize (GB) per VM name
        $DisksProperties | Group-Object -Property "vmName" | ForEach-Object {
            New-Object psobject -Property @{
                'VMName'              = $_.Name
                'allocatedDiskSizeGB' = ($_.Group | Measure-Object 'diskSizeGB' -Sum).Sum
            }
        }
        #endregion
    }

    End {
        # Nothing to cleanup
    }
}
