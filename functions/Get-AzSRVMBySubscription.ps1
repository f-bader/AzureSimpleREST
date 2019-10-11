<#
.SYNOPSIS
    Return a list of all virtual machines in a subscription

.DESCRIPTION
    Return a list of all virtual machines in a subscription

.PARAMETER SubscriptionId
    The SubscriptionId of the target subscription

.EXAMPLE
    Get-AzSRSubscription | Get-AzSRVMBySubscription

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRVMBySubscription {
    [CmdletBinding()]
    param (
        [Alias('id')]
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
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resources?api-version=2018-02-01&`$filter=resourceType+eq+'Microsoft.Compute/virtualMachines'"

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
        } catch {
            throw $($_.Exception.Message)
        }
    }

    End {

    }
}
