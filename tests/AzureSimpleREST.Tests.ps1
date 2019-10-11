Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
$Path = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulePath = (Get-Item $Path).Parent.FullName
$ModuleName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"
$ModuleManifest = Resolve-Path "$ModulePath\$ModuleName.psd1"

Describe "General project validation: $moduleName" {

    Context 'Basic Module Testing' {
        # Original idea from: https://kevinmarquette.github.io/2017-01-21-powershell-module-continious-delivery-pipeline/
        $scripts = Get-ChildItem $ModulePath -Include *.ps1, *.psm1, *.psd1 -Recurse
        $testCase = $scripts | Foreach-Object {
            @{
                FilePath = $_.fullname
                FileName = $_.Name

            }
        }
        It "Script <FileName> should be valid powershell" -TestCases $testCase {
            param(
                $FilePath,
                $FileName
            )

            $FilePath | Should Exist

            $contents = Get-Content -Path $FilePath -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
            $errors.Count | Should Be 0
        }

        It "Module '$moduleName' can import cleanly" {
            { Import-Module (Join-Path $ModulePath "$moduleName.psm1") -force } | Should Not Throw
        }
    }

    Context 'Manifest Testing' {
        It 'Valid Module Manifest' {
            {
                $Script:Manifest = Test-ModuleManifest -Path $ModuleManifest -ErrorAction Stop -WarningAction SilentlyContinue
            } | Should Not Throw
        }
        It 'Valid Manifest Name' {
            $Script:Manifest.Name | Should be $ModuleName
        }
        It 'Generic Version Check' {
            $Script:Manifest.Version -as [Version] | Should Not BeNullOrEmpty
        }
        It 'Valid Manifest Description' {
            $Script:Manifest.Description | Should Not BeNullOrEmpty
        }
        It 'Valid Manifest Root Module' {
            $Script:Manifest.RootModule | Should Be "$ModuleName.psm1"
        }
        It 'Valid Manifest GUID' {
            $Script:Manifest.Guid | Should be '52b2fee3-fc54-4b9a-ad52-4e382b194641'
        }
        It 'No Format File' {
            $Script:Manifest.ExportedFormatFiles | Should BeNullOrEmpty
        }

        It 'Required Modules' {
            $Script:Manifest.RequiredModules | Should Be @( 'Az.Accounts', 'Az.Network' )
        }
    }

    Context 'Exported Functions' {
        $ExportedFunctions = (Get-ChildItem -Path "$ModulePath\functions" -Filter *.ps1 | Select-Object -ExpandProperty Name ) -replace '\.ps1$'
        $testCase = $ExportedFunctions | Foreach-Object {@{FunctionName = $_}}
        It "Function <FunctionName> should be in manifest" -TestCases $testCase {
            param($FunctionName)
            $ManifestFunctions = $Manifest.ExportedFunctions.Keys
            $FunctionName -in $ManifestFunctions | Should Be $true
        }

        It 'Proper Number of Functions Exported compared to Manifest' {
            $ExportedCount = Get-Command -Module $ModuleName -CommandType Function | Measure-Object | Select-Object -ExpandProperty Count
            $ManifestCount = $Manifest.ExportedFunctions.Count

            $ExportedCount | Should be $ManifestCount
        }

        It 'Proper Number of Functions Exported compared to Files' {
            $ExportedCount = Get-Command -Module $ModuleName -CommandType Function | Measure-Object | Select-Object -ExpandProperty Count
            $FileCount = Get-ChildItem -Path "$ModulePath\functions" -Filter *.ps1 | Measure-Object | Select-Object -ExpandProperty Count

            $ExportedCount | Should be $FileCount
        }

        $InternalFunctions = (Get-ChildItem -Path "$ModulePath\internal\functions" -Filter *.ps1 | Select-Object -ExpandProperty Name ) -replace '\.ps1$'
        $testCase = $InternalFunctions | Foreach-Object {@{FunctionName = $_}}
        It "Internal function <FunctionName> is not directly accessible outside the module" -TestCases $testCase {
            param($FunctionName)
            { . $FunctionName } | Should Throw
        }
    }

    Context 'Exported Aliases' {
        It 'Proper Number of Aliases Exported compared to Manifest' {
            $ExportedCount = Get-Command -Module $ModuleName -CommandType Alias | Measure-Object | Select-Object -ExpandProperty Count
            $ManifestCount = $Manifest.ExportedAliases.Count

            $ExportedCount | Should be $ManifestCount
        }

        It 'Proper Number of Aliases Exported compared to Files' {
            $AliasCount = Get-ChildItem -Path "$ModulePath\functions" -Filter *.ps1 | Select-String "New-Alias" | Measure-Object | Select-Object -ExpandProperty Count
            $ManifestCount = $Manifest.ExportedAliases.Count

            $AliasCount  | Should be $ManifestCount
        }
    }
}

Describe "$ModuleName ScriptAnalyzer" -Tag 'Compliance' {
    $PSScriptAnalyzerSettings = @{
        Severity    = @('Error', 'Warning')
        ExcludeRule = @('PSUseSingularNouns')
    }
    # Test all functions with PSScriptAnalyzer
    $ScriptAnalyzerErrors = @()
    $ScriptAnalyzerErrors += Invoke-ScriptAnalyzer -Path "$ModulePath\functions" @PSScriptAnalyzerSettings
    $ScriptAnalyzerErrors += Invoke-ScriptAnalyzer -Path "$ModulePath\internal\functions" @PSScriptAnalyzerSettings
    # Get a list of all internal and Exported functions
    $InternalFunctions = Get-ChildItem -Path "$ModulePath\internal\functions" -Filter *.ps1 | Select-Object -ExpandProperty Name
    $ExportedFunctions = Get-ChildItem -Path "$ModulePath\functions" -Filter *.ps1 | Select-Object -ExpandProperty Name
    $AllFunctions = ($InternalFunctions + $ExportedFunctions) | Sort-Object
    $FunctionsWithErrors = $ScriptAnalyzerErrors.ScriptName | Sort-Object -Unique
    if ($ScriptAnalyzerErrors) {
        $testCase = $ScriptAnalyzerErrors | Foreach-Object {
            @{
                RuleName   = $_.RuleName
                ScriptName = $_.ScriptName
                Message    = $_.Message
                Severity   = $_.Severity
                Line       = $_.Line
            }
        }
        # Compare those with not successfull
        $FunctionsWithoutErrors = Compare-Object -ReferenceObject $AllFunctions -DifferenceObject $FunctionsWithErrors  | Select-Object -ExpandProperty InputObject
        Context 'ScriptAnalyzer Testing' {
            It "Function <ScriptName> should not use <Message> on line <Line>" -TestCases $testCase {
                param(
                    $RuleName,
                    $ScriptName,
                    $Message,
                    $Severity,
                    $Line
                )
                $ScriptName | Should BeNullOrEmpty
            }
        }
    } else {
        # Everything was perfect, let's show that as well
        $FunctionsWithoutErrors = $AllFunctions
    }

    # Show good functions in the test, the more green the better
    Context 'Successful ScriptAnalyzer Testing' {
        $testCase = $FunctionsWithoutErrors | Foreach-Object {
            @{
                ScriptName = $_
            }
        }
        It "Function <ScriptName> has no ScriptAnalyzerErrors" -TestCases $testCase {
            param(
                $ScriptName
            )
            $ScriptName | Should Not BeNullOrEmpty
        }
    }
}