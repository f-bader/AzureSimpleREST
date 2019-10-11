$FunctionName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"

Describe "$FunctionName Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        $AutomationAccountId = "/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzSRRG/providers/Microsoft.Automation/automationAccounts/LogAnalyticsAutomationAccount"
    }

    Context "Login successfull and two Update Deployment returned" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzCachedAccessToken -MockWith { return "MockedAuthorization" }
        Mock -ModuleName AzureSimpleREST -CommandName Invoke-RestMethod -MockWith {
            $ResponseJSON = '{"value":[{"id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzSRRG/providers/Microsoft.Automation/automationAccounts/LogAnalyticsAutomationAccount/softwareUpdateConfigurations/Monthly Linux Update","name":"Monthly Linux Update","properties":{"updateConfiguration":{"operatingSystem":"Linux","windows":null,"linux":{"includedPackageClassifications":"Critical, Security, Other","excludedPackageNameMasks":null,"includedPackageNameMasks":null,"rebootSetting":"IfRequired","IsInvalidPackageNameMasks":false},"targets":null,"duration":"PT2H","azureVirtualMachines":null,"nonAzureComputerNames":["nonAzureServer"]},"frequency":"Week","startTime":"2018-09-15T01:00:00+02:00","creationTime":"2018-09-14T08:49:50.79+00:00","lastModifiedTime":"2018-09-14T08:49:50.82+00:00","provisioningState":"Succeeded","nextRun":"2018-10-06T01:00:00+02:00","tasks":{"preTask":null,"postTask":null}}},{"id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzSRRG/providers/Microsoft.Automation/automationAccounts/LogAnalyticsAutomationAccount/softwareUpdateConfigurations/Initial Update","name":"Initial Update","properties":{"updateConfiguration":{"operatingSystem":"Linux","windows":null,"linux":{"includedPackageClassifications":"Critical, Security, Other","excludedPackageNameMasks":null,"includedPackageNameMasks":null,"rebootSetting":"IfRequired","IsInvalidPackageNameMasks":false},"targets":null,"duration":"PT2H","azureVirtualMachines":null,"nonAzureComputerNames":["NonAzureServer"]},"frequency":"OneTime","startTime":"2018-09-14T10:56:00+02:00","creationTime":"2018-09-14T08:50:32.663+00:00","lastModifiedTime":"2018-09-14T08:50:32.773+00:00","provisioningState":"Succeeded","nextRun":null,"tasks":{"preTask":null,"postTask":null}}}]}'
            $ResponseJSON | ConvertFrom-Json
        }
        $results = Get-AzSRUpdateDeployment -AutomationAccountResourceId $AutomationAccountId

        It "Should return the proper number of softwareUpdateConfigurations" {
            $results.Count | Should -Be 2
        }
        It "Should return the correct Update Deployment Name" {
            $results[1].Name | Should Be "Initial Update"
        }
    }
    Context "Login successfull and two Update Deployment returned" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzCachedAccessToken -MockWith { return "MockedAuthorization" }
        Mock -ModuleName AzureSimpleREST -CommandName Invoke-RestMethod -MockWith {
            $ResponseJSON = '{"id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzSRRG/providers/Microsoft.Automation/automationAccounts/LogAnalyticsAutomationAccount/softwareUpdateConfigurations/Monthly Linux Update","name":"Monthly Linux Update","properties":{"updateConfiguration":{"operatingSystem":"Linux","windows":null,"linux":{"includedPackageClassifications":"Critical, Security, Other","excludedPackageNameMasks":null,"includedPackageNameMasks":null,"rebootSetting":"IfRequired","IsInvalidPackageNameMasks":false},"targets":null,"duration":"PT2H","azureVirtualMachines":null,"nonAzureComputerNames":["nonAzureServer"]},"frequency":"Week","startTime":"2018-09-15T01:00:00+02:00","creationTime":"2018-09-14T08:49:50.79+00:00","lastModifiedTime":"2018-09-14T08:49:50.82+00:00","provisioningState":"Succeeded","nextRun":"2018-10-06T01:00:00+02:00","tasks":{"preTask":null,"postTask":null}}}'
            $ResponseJSON | ConvertFrom-Json
        }

        $results = Get-AzSRUpdateDeployment -AutomationAccountResourceId $AutomationAccountId -UpdateScheduleName "Monthly Linux Update"
        $ResultCount = $results  | Measure-Object | Select-Object -ExpandProperty Count

        It "Should return only one softwareUpdateConfiguration" {
            $ResultCount | Should -Be 1
        }
        It "Should return the correct Update Deployment Name" {
            $results.Name | Should Be "Monthly Linux Update"
        }
    }
    Context "Wrong Resource Id was used" {
        It "Should throw if invalid Resource Id is used" {
            { Get-AzSRUpdateDeployment -AutomationAccountResourceId "WrongAutomationAccountResourceId" } | Should -Throw
        }
    }
    Context "No Update Deployments present" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzCachedAccessToken -MockWith { return "MockedAuthorization" }
        Mock -ModuleName AzureSimpleREST -CommandName Invoke-RestMethod -MockWith {
            $ResponseJSON = '{"value": []}'
            $ResponseJSON | ConvertFrom-Json
        }

        $results = Get-AzSRUpdateDeployment -AutomationAccountResourceId $AutomationAccountId

        It "Should return nothing" {
            $results | Should -BeNullOrEmpty
        }
    }
    Context "Invoke-RestMethod throws" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzCachedAccessToken -MockWith { return "MockedAuthorization" }
        Mock -ModuleName AzureSimpleREST -CommandName Invoke-RestMethod -MockWith { throw "Wrong subscription context" }

        It "Should throw if request was invalid" {
            { Get-AzSRUpdateDeployment -AutomationAccountResourceId $AutomationAccountId } | Should -Throw
        }
    }
    Context "Login failed" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzCachedAccessToken -MockWith { throw "Ensure you have logged in (Connect-AzAccount) before calling this function." }

        It "Should throw if not logged in" {
            { Get-AzSRUpdateDeployment -SubscriptionId "429864a9-cfa2-40b4-b1c7-b65ce0485347" -VMName "MyFakeVM" } | Should -Throw
        }
    }
}