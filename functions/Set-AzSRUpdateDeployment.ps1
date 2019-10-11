<#
.SYNOPSIS
    Create a Azure Automation Update Deployment

.DESCRIPTION
    Create a Azure Automation Update Deployment

.PARAMETER AutomationAccountResourceId
    The Azure Resource Id of the Automation Account

.PARAMETER UpdateScheduleName
    The Name of the new Update Schedule or the name of an existing one

.PARAMETER StartTime
    Start time of the Update deployment

.PARAMETER AzureVMId
    Array of Azure VM Resource Ids

.PARAMETER operatingSystem
    Windows or Linux

.PARAMETER durationHours
    Maximum time for update installation.
    Default: 2 hours

.PARAMETER rebootSetting
    If the machines should reboot
    ifRequired: Only if a reboot is requested by one of the updates (default)
    neverReboot: Do not reboot the servers
    always: Always reboot the servers

.PARAMETER TimeZone
    A valid timezone. e.g. "Europe/Berlin"

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Set-AzSRUpdateDeployment {
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [Parameter(Mandatory = $true)]
        $AutomationAccountResourceId,
        [Parameter(Mandatory = $true)]
        $UpdateScheduleName,
        [Parameter(Mandatory = $true)]
        [ValidateScript( { (New-TimeSpan -Start (Get-Date) -End $_).Ticks -gt 0 } )]
        $StartTime,
        [Parameter(Mandatory = $true)]
        [string[]]$AzureVMId,
        [ValidateSet("Windows", "Linux")]
        $operatingSystem = "Windows",
        [int]$durationHours = 2,
        [ValidateSet("ifRequired", "neverReboot", "always")]
        $rebootSetting = "ifRequired",
        [ValidateScript(
            {
                try {
                    $AccessToken = Get-AzCachedAccessToken
                    $LoginHeader = @{
                        'authorization' = "Bearer $AccessToken"
                    }
                    $SupportedTimezones = Invoke-RestMethod -UseBasicParsing -Uri "https://s2.automation.ext.azure.com/api/Orchestrator/TimeZones" -Headers $LoginHeader -Method GET
                } catch {
                    throw $($_.Exception.Message)
                }

                if ($_ -in $SupportedTimezones.value) {
                    Return $true
                } else {
                    throw "$_ is not a valid Timezone"
                }
            }
        )]
        $TimeZone
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
        # Escape characters in schedule name
        $EscapedUpdateScheduleName = [uri]::EscapeDataString($UpdateScheduleName)
        # https://docs.microsoft.com/en-us/azure/templates/microsoft.automation/automationaccounts/softwareupdateconfigurations
        $uri = "https://management.azure.com/$AutomationAccountResourceId/softwareUpdateConfigurations/$($EscapedUpdateScheduleName)?api-version=2017-05-15-preview"

        # Format start time
        $StartTime = Get-Date $StartTime -Format "yyyy-MM-ddTHH:mm:ss.fff"
        #region Create payload based upon operating system
        switch ($operatingSystem) {
            "Windows" {
                $requestBody = @{
                    "name"       = "$UpdateScheduleName"
                    "properties" = @{
                        "updateConfiguration" = @{
                            "operatingSystem"      = "Windows"
                            "duration"             = "PT$($durationHours)H0M"
                            "windows"              = @{
                                "rebootSetting"                 = $rebootSetting
                                "includedUpdateClassifications" = "Critical,Definition,FeaturePack,Security,ServicePack,Tools,UpdateRollup,Updates"
                            }
                            "azureVirtualMachines" = @($AzureVMId)
                        }
                        "scheduleInfo"        = @{
                            "frequency" = 0
                            "startTime" = $StartTime
                            "timeZone"  = $TimeZone
                        }
                    }
                }
            }
            "Linux" {
                $requestBody = @{
                    "name"       = "$UpdateScheduleName"
                    "properties" = @{
                        "updateConfiguration" = @{
                            "operatingSystem"      = "Linux"
                            "duration"             = "PT$($durationHours)H0M"
                            "linux"                = @{
                                "excludedPackageNameMasks"       = @(
                                    "redhat-release-server.x86_64"
                                )
                                "rebootSetting"                  = $rebootSetting
                                "includedPackageClassifications" = "Critical,Security,Other"
                            }
                            "azureVirtualMachines" = @($AzureVMId)
                        }
                        "scheduleInfo"        = @{
                            "frequency" = 0
                            "startTime" = $StartTime
                            "timeZone"  = $TimeZone
                        }
                        "tasks"               = @{
                            "preTask"  = $null
                            "postTask" = $null
                        }
                    }
                }
            }
        }

        $params = @{
            ContentType = 'application/json'
            Headers     = $LoginHeader
            Method      = 'PUT'
            URI         = $uri
            Body        = ($requestBody | ConvertTo-Json -Depth 99 )
            Verbose     = $false
        }

        If ($PSCmdlet.ShouldProcess("Create update scheduler `"$UpdateScheduleName`"")) {
            Invoke-RestMethod @params | Out-Null
            Get-AzSRUpdateDeployment -AutomationAccountResourceId $AutomationAccountResourceId -UpdateScheduleName $UpdateScheduleName
        }
    }
}
New-Alias -Name Set-AzSRUpdateSchedule -Value Set-AzSRUpdateDeployment