$FunctionName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"

Describe "$FunctionName Integration Tests" -Tags "IntegrationTests" {
    Context "Login successfull and return value valid" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzCachedAccessToken -MockWith { return "MockedAuthorization" }
        Mock -ModuleName AzureSimpleREST -CommandName Invoke-RestMethod -MockWith {
            $ResponseJSON = '{"value": [{"id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/MyFakeRG/providers/Microsoft.Compute/virtualMachines/MyFakeVM","name":"MyFakeVM","type":"Microsoft.Compute/virtualMachines","location":"westeurope","tags":{}}]}'
            $ResponseJSON | ConvertFrom-Json
        }

        $results = Get-AzSRVMByName -SubscriptionId "429864a9-cfa2-40b4-b1c7-b65ce0485347" -VMName "MyFakeVM"

        It "Should return the proper Resource Name" {
            $results.Name | Should Be "MyFakeVM"
        }
        It "Should return the proper Resource type" {
            $results.type | Should Be "Microsoft.Compute/virtualMachines"
        }
        It "Should return the proper Location" {
            $results.location | Should Be "westeurope"
        }
        It "Should return the proper Tags" {
            $results.tags | Should BeNullOrEmpty
        }
        It "Should return the proper Resource Id" {
            $results.id | Should Be "/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/MyFakeRG/providers/Microsoft.Compute/virtualMachines/MyFakeVM"
        }
    }
    Context "Wrong Subscription Id was used" {
        It "Should throw if invalid Subscription Id is used" {
            { Get-AzSRVMByName -SubscriptionId "ThisIsNotAnSubscriptionId" -VMName "NotExistingVM" } | Should -Throw
        }
    }
    Context "VM is not present" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzCachedAccessToken -MockWith { return "MockedAuthorization" }
        Mock -ModuleName AzureSimpleREST -CommandName Invoke-RestMethod -MockWith {
            $ResponseJSON = '{"value": []}'
            $ResponseJSON | ConvertFrom-Json
        }

        $result = Get-AzSRVMByName -SubscriptionId "429864a9-cfa2-40b4-b1c7-b65ce0485347" -VMName "NotExistingVM"

        It "Should return nothing" {
            $result | Should -BeNullOrEmpty
        }
    }
    Context "Invoke-RestMethod throws" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzCachedAccessToken -MockWith { return "MockedAuthorization" }
        Mock -ModuleName AzureSimpleREST -CommandName Invoke-RestMethod -MockWith { throw "Wrong subscription context" }

        It "Should throw if request was invalid" {
            { Get-AzSRVMByName -SubscriptionId "429864a9-cfa2-40b4-b1c7-b65ce0485347" -VMName "MyFakeVM" } | Should -Throw
        }
    }
    Context "Login failed" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzCachedAccessToken -MockWith { throw "Ensure you have logged in (Connect-AzAccount) before calling this function." }

        It "Should throw if not logged in" {
            { Get-AzSRVMByName -SubscriptionId "429864a9-cfa2-40b4-b1c7-b65ce0485347" -VMName "MyFakeVM" } | Should -Throw
        }
    }
}