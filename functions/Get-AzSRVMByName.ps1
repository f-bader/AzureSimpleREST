<#
.SYNOPSIS
    Return a list of VMs from the specified subscription that match a name

.DESCRIPTION
    Return a list of VMs from the specified subscription that match a name
    Much like `Get-AzureRmResource -ResourceType "Microsoft.Compute/virtualMachines" `

.PARAMETER SubscriptionId
    The SubscriptionId of the target subscription

.PARAMETER VMName
    Name of the virtual Machine

.EXAMPLE
    Get-AzSRVMByName -SubscriptionId nnnn -VMName "MyVirtualMachine"

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRVMByName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
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
        [string]$SubscriptionId,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$VMName
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
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resources?api-version=2018-02-01&`$filter=resourceType eq 'Microsoft.Compute/virtualMachines' and name eq '$VMName'"

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
                "id"       = $_.id
                "name"     = $_.name
                "type"     = $_.type
                "location" = $_.location
                "tags"     = $_.tags
            }
        }
        while ($Response.PSObject.Properties.Name -match "NextLink") {
            $params.URI = $Response.NextLink
            $Response = Invoke-RestMethod @params
            $Response.value | ForEach-Object {
                New-Object psobject -Property @{
                    "id"       = $_.id
                    "name"     = $_.name
                    "type"     = $_.type
                    "location" = $_.location
                    "tags"     = $_.tags
                }
            }
        }
    }
    End {

    }
}
