$FunctionName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"

Describe "$FunctionName Integration Tests" -Tags "IntegrationTests" {
    Context "Calculate correct values" {
        It "Return 4.217 if 10 GB are used" {
            Get-AzSRBackupInstancePrice -AllocatedDiskSpace 10 | Should -Be 4.217
        }
        It "Return 8.433 if 100 GB are used" {
            Get-AzSRBackupInstancePrice -AllocatedDiskSpace 100 | Should -Be 8.433
        }
        It "Return 25.299 if 1024 GB are used" {
            Get-AzSRBackupInstancePrice -AllocatedDiskSpace 1024 | Should -Be 25.299
        }
    }
}