$FunctionName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"

Describe "$FunctionName Integration Tests" -Tags "IntegrationTests" {
    Context "Login successfull and return value valid" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzureRmCachedAccessToken -MockWith { return "MockedAuthorization" }
        Mock -ModuleName AzureSimpleREST -CommandName Invoke-RestMethod -MockWith {
            $ResponseJSON = '{"value": [{"id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/MyFakeRG/providers/Microsoft.Compute/virtualMachines/MyFakeVM","name":"MyFakeVM","type":"Microsoft.Compute/virtualMachines","location":"westeurope","tags":{}},{"id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/MyFakeRG/providers/Microsoft.Compute/virtualMachines/MyFakeVM","name":"MyFakeVM2","type":"Microsoft.Compute/virtualMachines","location":"westeurope","tags":{}}]}'
            $ResponseJSON | ConvertFrom-Json
        }

        $results = Get-AzSRVMBySubscription -SubscriptionId "429864a9-cfa2-40b4-b1c7-b65ce0485347"

        It "Should return the proper number of VMs" {
            $results.Count | Should -Be 2
        }
        It "Should return the correct VM Name" {
            $results[1].Name | Should Be "MyFakeVM2"
        }
    }
    Context "Wrong Subscription Id was used" {
        It "Should throw if invalid Subscription Id is used" {
            { Get-AzSRVMBySubscription -SubscriptionId "ThisIsNotAnSubscriptionId" } | Should -Throw
        }
    }
    Context "No VMs present" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzureRmCachedAccessToken -MockWith { return "MockedAuthorization" }
        Mock -ModuleName AzureSimpleREST -CommandName Invoke-RestMethod -MockWith {
            $ResponseJSON = '{"value": []}'
            $ResponseJSON | ConvertFrom-Json
        }

        $result = Get-AzSRVMBySubscription -SubscriptionId "429864a9-cfa2-40b4-b1c7-b65ce0485347"

        It "Should return nothing" {
            $result | Should -BeNullOrEmpty
        }
    }
    Context "Invoke-RestMethod throws" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzureRmCachedAccessToken -MockWith { return "MockedAuthorization" }
        Mock -ModuleName AzureSimpleREST -CommandName Invoke-RestMethod -MockWith { throw "Wrong subscription context" }

        It "Should throw if request was invalid" {
            { Get-AzSRVMBySubscription -SubscriptionId "429864a9-cfa2-40b4-b1c7-b65ce0485347" } | Should -Throw
        }
    }
    Context "Login failed" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzureRmCachedAccessToken -MockWith { throw "Ensure you have logged in (Connect-AzureRmAccount) before calling this function." }

        It "Should throw if not logged in" {
            { Get-AzSRVMBySubscription -SubscriptionId "429864a9-cfa2-40b4-b1c7-b65ce0485347" -VMName "MyFakeVM" } | Should -Throw
        }
    }
}