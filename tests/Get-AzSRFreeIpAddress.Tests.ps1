$FunctionName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"

Describe "$FunctionName Integration Tests" -Tags "IntegrationTests" {
    Context "Login successfull and check different types" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzureRmCachedAccessToken -MockWith { return "MockedAuthorization" }
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzureRmVirtualNetwork -MockWith {
            $ResponseJSON = '{"AddressSpace":{"AddressPrefixes":["10.0.0.0/22"],"AddressPrefixesText":"[\r\n  \"10.0.0.0/22\"\r\n]"},"DhcpOptions":{"DnsServers":null,"DnsServersText":"null"},"Subnets":[{"AddressPrefix":["10.0.0.0/24"],"IpConfigurations":[],"ResourceNavigationLinks":[],"NetworkSecurityGroup":null,"RouteTable":null,"ServiceEndpoints":[],"ServiceEndpointPolicies":[],"Delegations":[],"InterfaceEndpoints":[],"ProvisioningState":"Succeeded","IpConfigurationsText":"[]","ResourceNavigationLinksText":"[]","NetworkSecurityGroupText":"null","RouteTableText":"null","ServiceEndpointText":"[]","ServiceEndpointPoliciesText":"[]","InterfaceEndpointsText":"[]","DelegationsText":"[]","Name":"AzSRSubnet-1","Etag":"W/\"3dfb654e-255c-442e-8854-7c913f0c7e4e\"","Id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork/subnets/AzSRSubnet-1"},{"AddressPrefix":["10.0.1.0/24"],"IpConfigurations":[],"ResourceNavigationLinks":[],"NetworkSecurityGroup":null,"RouteTable":null,"ServiceEndpoints":[],"ServiceEndpointPolicies":[],"Delegations":[],"InterfaceEndpoints":[],"ProvisioningState":"Succeeded","IpConfigurationsText":"[]","ResourceNavigationLinksText":"[]","NetworkSecurityGroupText":"null","RouteTableText":"null","ServiceEndpointText":"[]","ServiceEndpointPoliciesText":"[]","InterfaceEndpointsText":"[]","DelegationsText":"[]","Name":"AzSRSubnet-2","Etag":"W/\"3dfb654e-255c-442e-8854-7c913f0c7e4e\"","Id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork/subnets/AzSRSubnet-2"}],"VirtualNetworkPeerings":[],"ProvisioningState":"Succeeded","EnableDdosProtection":false,"EnableVmProtection":false,"DdosProtectionPlan":null,"AddressSpaceText":"{\r\n  \"AddressPrefixes\": [\r\n    \"10.0.0.0/22\"\r\n  ]\r\n}","DhcpOptionsText":"{}","SubnetsText":"[\r\n  {\r\n    \"Delegations\": [],\r\n    \"Name\": \"AzSRSubnet-1\",\r\n    \"Etag\": \"W/\\\"3dfb654e-255c-442e-8854-7c913f0c7e4e\\\"\",\r\n    \"Id\": \"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork/subnets/AzSRSubnet-1\",\r\n    \"AddressPrefix\": [\r\n      \"10.0.0.0/24\"\r\n    ],\r\n    \"IpConfigurations\": [],\r\n    \"ResourceNavigationLinks\": [],\r\n    \"ServiceEndpoints\": [],\r\n    \"ServiceEndpointPolicies\": [],\r\n    \"InterfaceEndpoints\": [],\r\n    \"ProvisioningState\": \"Succeeded\"\r\n  },\r\n  {\r\n    \"Delegations\": [],\r\n    \"Name\": \"AzSRSubnet-2\",\r\n    \"Etag\": \"W/\\\"3dfb654e-255c-442e-8854-7c913f0c7e4e\\\"\",\r\n    \"Id\": \"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork/subnets/AzSRSubnet-2\",\r\n    \"AddressPrefix\": [\r\n      \"10.0.1.0/24\"\r\n    ],\r\n    \"IpConfigurations\": [],\r\n    \"ResourceNavigationLinks\": [],\r\n    \"ServiceEndpoints\": [],\r\n    \"ServiceEndpointPolicies\": [],\r\n    \"InterfaceEndpoints\": [],\r\n    \"ProvisioningState\": \"Succeeded\"\r\n  }\r\n]","VirtualNetworkPeeringsText":"[]","EnableDdosProtectionText":"false","DdosProtectionPlanText":"null","EnableVmProtectionText":"false","ResourceGroupName":"AzureSimpleREST","Location":"westeurope","ResourceGuid":"41c493a3-8998-4074-9e75-e6e154cb136d","Type":"Microsoft.Network/virtualNetworks","Tag":null,"TagsTable":null,"Name":"AzSRNetwork","Etag":"W/\"3dfb654e-255c-442e-8854-7c913f0c7e4e\"","Id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork"}'
            $ResponseJSON | ConvertFrom-Json
        }

        $results = Get-AzSRFreeIpAddress -NetworkName "AzSRNetwork" -ResourceGroupName "AzureSimpleREST"

        It "Should return 502 free IP addresses in all subnets" {
            $results.Count | Should Be 502
        }

        $results = Get-AzSRFreeIpAddress -NetworkName "AzSRNetwork" -ResourceGroupName "AzureSimpleREST" -SubnetName "AzSRSubnet-1"

        It "Should return 251 free IP addresses in one subnet" {
            $results.Count | Should Be 251
        }

        $results = Get-AzSRFreeIpAddress -NetworkName "AzSRNetwork" -ResourceGroupName "AzureSimpleREST" -SubnetName "AzSRSubnet-1" -First 10
        It "Should return 10 free IP addresses if parameter -First is 10" {
            $results.Count | Should Be 10
        }

        # One used ip address
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzureRmVirtualNetwork -MockWith {
            $ResponseJSON = '{"AddressSpace":{"AddressPrefixes":["10.0.0.0/22"],"AddressPrefixesText":"[\r\n  \"10.0.0.0/22\"\r\n]"},"DhcpOptions":{"DnsServers":null,"DnsServersText":"null"},"Subnets":[{"AddressPrefix":["10.0.0.0/24"],"IpConfigurations":[{"PrivateIpAddress":"10.0.0.4","PrivateIpAllocationMethod":"Dynamic","Subnet":{"AddressPrefix":null,"IpConfigurations":[],"ResourceNavigationLinks":[],"NetworkSecurityGroup":null,"RouteTable":null,"ServiceEndpoints":[],"ServiceEndpointPolicies":[],"Delegations":[],"InterfaceEndpoints":[],"ProvisioningState":null,"IpConfigurationsText":"[]","ResourceNavigationLinksText":"[]","NetworkSecurityGroupText":"null","RouteTableText":"null","ServiceEndpointText":"[]","ServiceEndpointPoliciesText":"[]","InterfaceEndpointsText":"[]","DelegationsText":"[]","Name":null,"Etag":null,"Id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork/subnets/AzSRSubnet-1"},"PublicIpAddress":null,"ProvisioningState":"Succeeded","SubnetText":"{\r\n  \"Delegations\": [],\r\n  \"Id\": \"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork/subnets/AzSRSubnet-1\"\r\n}","PublicIpAddressText":"null","Name":"ipconfig1","Etag":"W/\"67c50585-dd5a-481f-8ff0-c9769de97376\"","Id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/networkInterfaces/AzSRSampleNIC/ipConfigurations/ipconfig1"}],"ResourceNavigationLinks":[],"NetworkSecurityGroup":null,"RouteTable":null,"ServiceEndpoints":[],"ServiceEndpointPolicies":[],"Delegations":[],"InterfaceEndpoints":[],"ProvisioningState":"Succeeded","IpConfigurationsText":"[\r\n  {\r\n    \"Name\": \"ipconfig1\",\r\n    \"Etag\": \"W/\\\"67c50585-dd5a-481f-8ff0-c9769de97376\\\"\",\r\n    \"Id\": \"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/networkInterfaces/AzSRSampleNIC/ipConfigurations/ipconfig1\",\r\n    \"PrivateIpAddress\": \"10.0.0.4\",\r\n    \"PrivateIpAllocationMethod\": \"Dynamic\",\r\n    \"Subnet\": {\r\n      \"Delegations\": [],\r\n      \"Id\": \"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork/subnets/AzSRSubnet-1\"\r\n    },\r\n    \"ProvisioningState\": \"Succeeded\"\r\n  }\r\n]","ResourceNavigationLinksText":"[]","NetworkSecurityGroupText":"null","RouteTableText":"null","ServiceEndpointText":"[]","ServiceEndpointPoliciesText":"[]","InterfaceEndpointsText":"[]","DelegationsText":"[]","Name":"AzSRSubnet-1","Etag":"W/\"45e73068-1896-40de-96ec-4e36e42fb830\"","Id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork/subnets/AzSRSubnet-1"},{"AddressPrefix":["10.0.1.0/24"],"IpConfigurations":[],"ResourceNavigationLinks":[],"NetworkSecurityGroup":null,"RouteTable":null,"ServiceEndpoints":[],"ServiceEndpointPolicies":[],"Delegations":[],"InterfaceEndpoints":[],"ProvisioningState":"Succeeded","IpConfigurationsText":"[]","ResourceNavigationLinksText":"[]","NetworkSecurityGroupText":"null","RouteTableText":"null","ServiceEndpointText":"[]","ServiceEndpointPoliciesText":"[]","InterfaceEndpointsText":"[]","DelegationsText":"[]","Name":"AzSRSubnet-2","Etag":"W/\"45e73068-1896-40de-96ec-4e36e42fb830\"","Id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork/subnets/AzSRSubnet-2"}],"VirtualNetworkPeerings":[],"ProvisioningState":"Succeeded","EnableDdosProtection":false,"EnableVmProtection":false,"DdosProtectionPlan":null,"AddressSpaceText":"{\r\n  \"AddressPrefixes\": [\r\n    \"10.0.0.0/22\"\r\n  ]\r\n}","DhcpOptionsText":"{}","SubnetsText":"[\r\n  {\r\n    \"Delegations\": [],\r\n    \"Name\": \"AzSRSubnet-1\",\r\n    \"Etag\": \"W/\\\"45e73068-1896-40de-96ec-4e36e42fb830\\\"\",\r\n    \"Id\": \"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork/subnets/AzSRSubnet-1\",\r\n    \"AddressPrefix\": [\r\n      \"10.0.0.0/24\"\r\n    ],\r\n    \"IpConfigurations\": [\r\n      {\r\n        \"Name\": \"ipconfig1\",\r\n        \"Etag\": \"W/\\\"67c50585-dd5a-481f-8ff0-c9769de97376\\\"\",\r\n        \"Id\": \"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/networkInterfaces/AzSRSampleNIC/ipConfigurations/ipconfig1\",\r\n        \"PrivateIpAddress\": \"10.0.0.4\",\r\n        \"PrivateIpAllocationMethod\": \"Dynamic\",\r\n        \"Subnet\": {\r\n          \"Delegations\": [],\r\n          \"Id\": \"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork/subnets/AzSRSubnet-1\"\r\n        },\r\n        \"ProvisioningState\": \"Succeeded\"\r\n      }\r\n    ],\r\n    \"ResourceNavigationLinks\": [],\r\n    \"ServiceEndpoints\": [],\r\n    \"ServiceEndpointPolicies\": [],\r\n    \"InterfaceEndpoints\": [],\r\n    \"ProvisioningState\": \"Succeeded\"\r\n  },\r\n  {\r\n    \"Delegations\": [],\r\n    \"Name\": \"AzSRSubnet-2\",\r\n    \"Etag\": \"W/\\\"45e73068-1896-40de-96ec-4e36e42fb830\\\"\",\r\n    \"Id\": \"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork/subnets/AzSRSubnet-2\",\r\n    \"AddressPrefix\": [\r\n      \"10.0.1.0/24\"\r\n    ],\r\n    \"IpConfigurations\": [],\r\n    \"ResourceNavigationLinks\": [],\r\n    \"ServiceEndpoints\": [],\r\n    \"ServiceEndpointPolicies\": [],\r\n    \"InterfaceEndpoints\": [],\r\n    \"ProvisioningState\": \"Succeeded\"\r\n  }\r\n]","VirtualNetworkPeeringsText":"[]","EnableDdosProtectionText":"false","DdosProtectionPlanText":"null","EnableVmProtectionText":"false","ResourceGroupName":"AzureSimpleREST","Location":"westeurope","ResourceGuid":"41c493a3-8998-4074-9e75-e6e154cb136d","Type":"Microsoft.Network/virtualNetworks","Tag":null,"TagsTable":null,"Name":"AzSRNetwork","Etag":"W/\"45e73068-1896-40de-96ec-4e36e42fb830\"","Id":"/subscriptions/429864a9-cfa2-40b4-b1c7-b65ce0485347/resourceGroups/AzureSimpleREST/providers/Microsoft.Network/virtualNetworks/AzSRNetwork"}'
            $ResponseJSON | ConvertFrom-Json
        }

        $results = Get-AzSRFreeIpAddress -NetworkName "AzSRNetwork" -ResourceGroupName "AzureSimpleREST" -SubnetName "AzSRSubnet-1"
        It "Should return 250 free IP addresses if one is used" {
            $results.Count | Should Be 250
        }

    }
    Context "Login failed" {
        Mock -ModuleName AzureSimpleREST -CommandName Get-AzureRmCachedAccessToken -MockWith { throw "Ensure you have logged in (Connect-AzureRmAccount) before calling this function." }

        It "Should throw if not logged in" {
            { Get-AzSRFreeIpAddress -NetworkName "AzSRNetwork" -ResourceGroupName "AzureSimpleREST" -SubnetName "AzSRSubnet-1"  } | Should -Throw
        }
    }
}