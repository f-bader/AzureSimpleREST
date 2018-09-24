<#
.SYNOPSIS
    How much does a specific VM Azure Backup cost 

.DESCRIPTION
    Azure Backup pricing is based on consumption and a base price.
    This function calculates the instance price for a given VM

    Pricing based on https://azure.microsoft.com/en-us/pricing/details/backup/
    Instance size               Price
    Instance < or = 50 GB            = 4.217 €
    Instance is > 50 but < or = 500  = 8.433 €
    Instance > 500 GB     	         = 8.433 € for each 500 GB increment
.PARAMETER AllocatedDiskSpace
    Allocated Disk Space of the VM in GB

.EXAMPLE
    Get-AzSRBackupInstancePrice -AllocatedDiskSpace 120

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRBackupInstancePrice {
    [CmdletBinding()]
    param (
        [Alias('allocatedDiskSizeGB')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [int]$AllocatedDiskSpace
    )
    Process {

        if ( $AllocatedDiskSpace -le 50 ) {
            $Price = 4.217
        } elseif ( $AllocatedDiskSpace -gt 50 -and $AllocatedDiskSpace -lt 500 ) {
            $Price = 8.433
        } else {
            # How many 500 GB increments are there
            $Increments = [math]::Ceiling( $AllocatedDiskSpace / 500 )
            $Price = ( 8.433 * $Increments )
        }

        Return $Price
    }
}