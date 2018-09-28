$FunctionName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"

Describe "$FunctionName Integration Tests" -Tags "IntegrationTests" {
    Mock -ModuleName AzureSimpleREST -CommandName Get-AzureRmCachedAccessToken -MockWith { return "MockedAuthorization" }
    Mock -ModuleName AzureSimpleREST -CommandName Invoke-RestMethod -MockWith {
        $ResponseJSON = '{"value":[{"id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347","subscriptionId":"429864a9-cfa2-40b4-b1c7-b65ce0485347","displayName":"Pay as you go","state":"Enabled","subscriptionPolicies":{"locationPlacementId":"Public_2014-09-01","quotaId":"PayAsYouGo_2014-09-01","spendingLimit":"Off"},"authorizationSource":"Legacy"}]}'
        $ResponseJSON | ConvertFrom-Json
    }

    $results = Get-AzSRSubscription

    It "Should return the proper Subcription Id" {
        $results.subscriptionId | Should Be "429864a9-cfa2-40b4-b1c7-b65ce0485347"
    }

    It "Should show the proper display Name" {
        $results.displayName | Should Be "Pay as you go"
    }

    It "Should show the proper Subscription state" {
        $results.state | Should Be "Enabled"
    }

    It "Should show the proper thumbprint" {
        $results.locationPlacementId | Should Be "Public_2014-09-01"
    }

    It "Should show the proper offer" {
        $results.quotaId | Should Be "PayAsYouGo_2014-09-01"
    }

    It "Should show the proper spending limit" {
        $results.spendingLimit | Should Be "Off"
    }

    It "Should show the proper thumbprint" {
        $results.authorizationSource | Should Be "Legacy"
    }

}