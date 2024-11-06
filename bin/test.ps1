#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'BuildHelpers'; ModuleVersion = '2.0.1' }
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

# Override JSON Schema File
if (-not (Test-Path "$env:SCOOP_HOME\schema.json.bak")) {
    Move-Item "$env:SCOOP_HOME\schema.json" "$env:SCOOP_HOME\schema.json.bak" -Force
}
Copy-Item (Join-Path $PSScriptRoot 'schema.json') "$env:SCOOP_HOME\schema.json" -Force

$pesterConfig = New-PesterConfiguration -Hashtable @{
    Run    = @{
        Path     = "$PSScriptRoot/.."
        PassThru = $true
    }
    Output = @{
        Verbosity = 'Detailed'
    }
}
$result = Invoke-Pester -Configuration $pesterConfig

Move-Item "$env:SCOOP_HOME\schema.json.bak" "$env:SCOOP_HOME\schema.json" -Force

exit $result.FailedCount
