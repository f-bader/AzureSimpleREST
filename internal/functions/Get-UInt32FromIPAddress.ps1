<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER IPAddress
Parameter description

.EXAMPLE
An example

.NOTES
    Website: https://powershell.org/forums/topic/ip-address-math/
    Copyright: (c) 2014 Dave Wyatt
    License: MIT https://opensource.org/licenses/MIT
    Used with permission: https://twitter.com/msh_dave/status/1037475306381094913
#>
function Get-UInt32FromIPAddress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ipaddress]
        $IPAddress
    )

    $bytes = $IPAddress.GetAddressBytes()

    if ([BitConverter]::IsLittleEndian) {
        [Array]::Reverse($bytes)
    }

    return [BitConverter]::ToUInt32($bytes, 0)
}