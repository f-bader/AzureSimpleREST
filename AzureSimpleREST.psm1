﻿#Requires -Version 3.0

# Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\functions\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\internal\functions\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try { . $import.fullname }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Export everything in the public folder
Export-ModuleMember -Function $Public.Basename -Alias *