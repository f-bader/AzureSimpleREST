$FunctionName = $ModuleName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"

Describe "$FunctionName Integration Tests" -Tags "IntegrationTests" {
    Mock -ModuleName AzureSimpleREST -CommandName Get-AzureRmCachedAccessToken -MockWith { return "MockedAuthorization" }
    Mock -ModuleName AzureSimpleREST -CommandName Invoke-RestMethod -MockWith {
        $ResponseJSON = '{"properties":{"osProfile":{"computerName":"MYFAKEVM"},"vmId":"fc1452ca-bb72-4a9d-a8a8-0a19ae6daa56","availabilitySet":{"id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/MyFakeRG/providers/Microsoft.Compute/availabilitySets/AS-DOMAINCONTROLLER"},"hardwareProfile":{"vmSize":"Standard_B1ms"},"storageProfile":{"osDisk":{"osType":"Windows","name":"MyFakeVM_OsDisk_1_cf45d9b8821740e1ab89fd2d5dcd4df9","createOption":"Attach","caching":"ReadWrite","managedDisk":{"storageAccountType":"Standard_LRS","id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/MyFakeRG/providers/Microsoft.Compute/disks/MyFakeVM_OsDisk_1_cf45d9b8821740e1ab89fd2d5dcd4df9"},"diskSizeGB":127},"dataDisks":[]},"networkProfile":{"networkInterfaces":[{"id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/MyFakeRG/providers/Microsoft.Network/networkInterfaces/MyFakeVM120","properties":{"primary":true}}]},"provisioningState":"Succeeded"},"resources":[{"properties":{"autoUpgradeMinorVersion":true,"settings":{"workspaceId":"c40ee683-a468-4a9c-8332-e40b41f595b7"},"provisioningState":"Succeeded","publisher":"Microsoft.EnterpriseCloud.Monitoring","type":"MicrosoftMonitoringAgent","typeHandlerVersion":"1.0"},"type":"Microsoft.Compute/virtualMachines/extensions","location":"westeurope","id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/MyFakeRG/providers/Microsoft.Compute/virtualMachines/MyFakeVM/extensions/MicrosoftMonitoringAgent","name":"MicrosoftMonitoringAgent"}],"type":"Microsoft.Compute/virtualMachines","location":"westeurope","id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/MyFakeRG/providers/Microsoft.Compute/virtualMachines/MyFakeVM","name":"MyFakeVM"}'
        $ResponseJSON | ConvertFrom-Json
    }

    $results = Get-AzSRVM -ResourceId "/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/MyFakeRG/providers/Microsoft.Compute/virtualMachines/MyFakeVM"

    It "Should return the proper VM Name" {
        $results.vmName | Should Be "MyFakeVM"
    }
    It "Should return the proper Resource Group" {
        $results.resourceGroup | Should Be "MyFakeRG"
    }
    It "Should return the proper VM Id" {
        $results.vmId | Should Be "fc1452ca-bb72-4a9d-a8a8-0a19ae6daa56"
    }
    It "Should return the proper VM Size" {
        $results.vmSize | Should Be "Standard_B1ms"
    }
    It "Should return the proper Computer Name" {
        $results.computerName | Should Be "MYFAKEVM"
    }
    It "Should return the proper Location" {
        $results.location | Should Be "westeurope"
    }
    It "Should return the proper Tags" {
        $results.tags | Should BeNullOrEmpty
    }
    It "Should return the proper Resource Id" {
        $results.ResourceId | Should Be "/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/MyFakeRG/providers/Microsoft.Compute/virtualMachines/MyFakeVM"
    }

}