<#
.SYNOPSIS
    Get one or all Azure Automation Update Deployment Configurations

.DESCRIPTION
    Get one or all Azure Automation Update Deployment Configurations

    https://docs.microsoft.com/en-us/azure/templates/microsoft.automation/automationaccounts/softwareupdateconfigurations

.PARAMETER AutomationAccountResourceId
    The Azure Resource Id of the Automation Account

.PARAMETER UpdateScheduleName
    The Name of the Update Deployment. If none is specified all are returned

.EXAMPLE
    Get-AzureRmOperationalInsightsWorkspace | Get-AzSRLogAnalyticsLinkedAutomationAccount | Get-AzSRUpdateDeployment

.NOTES
    Copyright: (c) 2018 Fabian Bader
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-AzSRUpdateDeployment {
    [CmdletBinding()]
    param (
        [Alias('resourceId')]
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript(
            {
                if ($_ -match "subscriptions\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/resourcegroups\/[\w\d-\.]+\/providers\/microsoft\.Automation\/automationAccounts\/[\w|()-]+$" ) {
                    $true
                } else {
                    throw "Not  a valid 'microsoft.RecoveryServices/vaults' URI"
                }
            }
        )]
        [string]$AutomationAccountResourceId,
        [Parameter(Mandatory = $false)]
        [string]$UpdateScheduleName
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

        # Escape characters in schedule name
        if ([string]::IsNullOrWhiteSpace($UpdateScheduleName)) {
            $uri = "https://management.azure.com/$AutomationAccountResourceId/softwareUpdateConfigurations?api-version=2017-05-15-preview"
        } else {
            $EscapedUpdateScheduleName = [uri]::EscapeDataString($UpdateScheduleName)
            $uri = "https://management.azure.com/$AutomationAccountResourceId/softwareUpdateConfigurations/$($EscapedUpdateScheduleName)?api-version=2017-05-15-preview"
        }

        $params = @{
            ContentType = 'application/x-www-form-urlencoded'
            Headers     = $LoginHeader
            Method      = 'Get'
            URI         = $uri
            Verbose     = $false
        }

        try {
            $Response = Invoke-RestMethod @params
            if ( "Value" -in $Response.PSobject.Properties.name ) {
                # Multiple returns
                $Responses = $Response.Value
            } else {
                # Only one return
                $Responses = $Response
            }
            $Responses | ForEach-Object {
                #region Property conversion
                if ($_.properties.scheduleInfo.startTime) {
                    $scheduleInfoStartTime = (Get-Date $_.properties.scheduleInfo.startTime)
                } else {
                    $scheduleInfoStartTime = $null
                }
                if ($_.properties.scheduleInfo.expiryTime) {
                    if ( $_.properties.scheduleInfo.expiryTime -match "^9999-12-31" ) {
                        $scheduleInfoExpiryTime = $null
                    } else {
                        $scheduleInfoExpiryTime = (Get-Date $_.properties.scheduleInfo.expiryTime -ErrorAction SilentlyContinue)
                    }
                } else {
                    $scheduleInfoExpiryTime = $null
                }
                if ($_.properties.scheduleInfo.nextRun) {
                    $scheduleInfoNextRun = (Get-Date $_.properties.scheduleInfo.nextRun)
                } else {
                    $scheduleInfoNextRun = $null
                }
                if ($_.properties.scheduleInfo.creationTime) {
                    $scheduleInfoCreationTime = (Get-Date $_.properties.scheduleInfo.creationTime)
                } else {
                    $scheduleInfoCreationTime = $null
                }
                if ($_.properties.scheduleInfo.lastModifiedTime) {
                    $scheduleInfoLastModifiedTime = (Get-Date $_.properties.scheduleInfo.lastModifiedTime)
                } else {
                    $scheduleInfoLastModifiedTime = $null
                }
                if ($_.properties.creationTime) {
                    $creationTime = (Get-Date $_.properties.creationTime)
                } else {
                    $creationTime = $null
                }
                if ($_.properties.lastModifiedTime) {
                    $lastModifiedTime = (Get-Date $_.properties.lastModifiedTime)
                } else {
                    $lastModifiedTime = $null
                }
                if ($_.properties.error) {
                    $DeyplomentError = @{
                        code    = $_.properties.error.code
                        message = $_.properties.error.message
                    }
                } else {
                    $DeyplomentError = $null
                }
                if ($_.properties.updateConfiguration.operatingSystem -eq "Windows") {
                    $windowsUpdateConfiguration = @{
                        includedUpdateClassifications = $_.properties.updateConfiguration.windows.includedUpdateClassifications
                        excludedKbNumbers             = $_.properties.updateConfiguration.windows.excludedKbNumbers
                        includedKbNumbers             = $_.properties.updateConfiguration.windows.includedKbNumbers
                        rebootSetting                 = $_.properties.updateConfiguration.windows.rebootSetting
                        IsInvalidKbNumbers            = $_.properties.updateConfiguration.windows.IsInvalidKbNumbers
                    }
                    $linuxUpdateConfiguration = $null
                } elseif ($_.properties.updateConfiguration.operatingSystem -eq "Linux ") {
                    $windowsUpdateConfiguration = $null
                    $linuxUpdateConfiguration = @{
                        includedUpdateClassifications = $_.properties.updateConfiguration.linux.includedPackageClassifications
                        excludedKbNumbers             = $_.properties.updateConfiguration.linux.excludedPackageNameMasks
                        includedKbNumbers             = $_.properties.updateConfiguration.linux.includedPackageNameMasks
                        rebootSetting                 = $_.properties.updateConfiguration.linux.rebootSetting
                        IsInvalidKbNumbers            = $_.properties.updateConfiguration.linux.IsInvalidPackageNameMasks
                    }
                } else {
                    $windowsUpdateConfiguration = $null
                    $linuxUpdateConfiguration = $null
                }
                #endregion
                New-Object psobject -Property @{
                    id                  = $_.id
                    Name                = $_.name
                    updateConfiguration = @{
                        operatingSystem       = $_.properties.updateConfiguration.operatingSystem
                        windows               = $windowsUpdateConfiguration
                        linux                 = $linuxUpdateConfiguration
                        duration              = $_.properties.updateConfiguration.duration
                        azureVirtualMachines  = $_.properties.updateConfiguration.azureVirtualMachines
                        nonAzureComputerNames = $_.properties.updateConfiguration.nonAzureComputerNames
                    }
                    scheduleInfo        = @{
                        description             = $_.properties.scheduleInfo.description
                        startTime               = $scheduleInfoStartTime
                        startTimeOffsetMinutes  = $_.properties.scheduleInfo.startTimeOffsetMinutes
                        expiryTime              = $scheduleInfoExpiryTime
                        expiryTimeOffsetMinutes = $_.properties.scheduleInfo.expiryTimeOffsetMinutes
                        isEnabled               = $_.properties.scheduleInfo.isEnabled
                        nextRun                 = $scheduleInfoNextRun
                        nextRunOffsetMinutes    = $_.properties.scheduleInfo.nextRunOffsetMinutes
                        interval                = $_.properties.scheduleInfo.interval
                        frequency               = $_.properties.scheduleInfo.frequency
                        creationTime            = $scheduleInfoCreationTime
                        lastModifiedTime        = $scheduleInfoLastModifiedTime
                        timeZone                = $_.properties.scheduleInfo.timeZone
                        advancedSchedule        = $_.properties.scheduleInfo.advancedSchedule
                    }
                    provisioningState   = $_.properties.provisioningState
                    createdBy           = $_.properties.createdBy
                    error               = $DeyplomentError
                    tasks               = $_.properties.tasks
                    creationTime        = $creationTime
                    lastModifiedBy      = $_.properties.lastModifiedBy
                    lastModifiedTime    = $lastModifiedTime
                }
            }
        } catch {
            throw $($_.Exception.Message)
        }
    }
}
New-Alias -name Get-AzSRUpdateSchedule -value Get-AzSRUpdateDeployment