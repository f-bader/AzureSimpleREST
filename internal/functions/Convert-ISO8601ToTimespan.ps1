<#
.SYNOPSIS
    Convert ISO8601 duration to a .NET timespan object

.DESCRIPTION
    Convert ISO8601 duration to a .NET timespan object
    https://en.wikipedia.org/wiki/ISO_8601#Durations

    A month is always 30 days
    A year is always 365 days
    No support for miliseconds

.PARAMETER Duration
    ISO8601 duration

.EXAMPLE
    Convert-ISO8601ToTimespan -Duration "PT39M6.3580667S"

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Convert-ISO8601ToTimespan {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                if ($_ -match "^P(?<years>\d*Y)?(?<months>\d*M)?(?<days>\d*D)?(T)?(?<hours>\d*H)?(?<minutes>\d*M)?(?<seconds>[\d.]*S)?$" ) {
                    $true
                } else {
                    throw "Not a valid ISO8601 duration"
                }
            }
        )]
        [string]$Duration
    )

    Process {
        if ($Duration -match "^P(?<years>\d*Y)?(?<months>\d*M)?(?<days>\d*D)?(T)?(?<hours>\d*H)?(?<minutes>\d*M)?(?<seconds>[\d.]*S)?$" ) {
            $years = [Int32]($matches['years'] -replace "[^\d.,]")
            $months = [Int32]($matches['months'] -replace "[^\d.,]")
            $days = [Int32]($matches['days'] -replace "[^\d.,]")
            $hours = [Int32]($matches['hours'] -replace "[^\d.,]")
            $minutes = [Int32]($matches['minutes'] -replace "[^\d.,]")
            $seconds = [Int32]($matches['seconds'] -replace "[^\d.,]")
            #region Convert years and month to days
            if ($years -gt 0) {
                $days = $years * 365 + $days
            }
            if ($months -gt 0) {
                $days = $months * 30 + $days
            }
            #endregion 
            New-TimeSpan -Days $days -Hours $hours -Minutes $minutes -Seconds $seconds
        }
    }
}