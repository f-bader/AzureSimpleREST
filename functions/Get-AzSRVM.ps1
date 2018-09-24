<#
.SYNOPSIS
    Return basic information about a virtual machine

.DESCRIPTION
    Return basic information about a virtual machine
    Much faster than Get-AzurRmVM but only a fraction of the properties get returned.
    Perfect to check if a VM is still existing

.PARAMETER ResourceId
    The Resource Id of the VM

.EXAMPLE
    Get-AzSRVM -ResourceId "/subscriptions/nnnnn/resourceGroups/MyResourceGroup/providers/Microsoft.Compute/virtualMachines/MyVirtualMachine"

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRVM {
    [CmdletBinding()]
    param (
        [Alias('VMId')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                if ($_ -match "subscriptions\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/resourcegroups\/[\w\d-]+\/providers\/Microsoft\.Compute\/virtualMachines\/[\w\d-]+$" ) {
                    $true
                } else {
                    throw "Not a valid 'Microsoft.Compute/virtualMachines' URI"
                }
            }
        )]
        [string]$ResourceId
    )
    Begin {
        $baseURI = "https://management.azure.com"
        $suffixURI = "?api-version=2017-12-01"

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
        $uri = $baseURI + $ResourceId + $suffixURI
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
                New-Object psobject -Property @{
                    'vmName'          = $_.name
                    'resourceGroup'   = $ResourceId -replace '^.*resourceGroups.(.*).providers.*$', '$1'
                    'vmId'            = $_.properties.vmId
                    'vmSize'          = $_.properties.hardwareProfile.vmSize
                    'computerName'    = $_.properties.osProfile.computerName
                    'location'        = $_.location
                    'businessService' = $_.tags.BusinessService
                    'costCenter'      = $_.tags.CostCenter
                    'ResourceId'      = $ResourceId
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