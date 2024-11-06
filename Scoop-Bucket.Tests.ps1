if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
# Override JSON Schema File
Move-Item "$env:SCOOP_HOME\schema.json" "$env:SCOOP_HOME\schema.json.bak" -Force
Copy-Item (Join-Path $PSScriptRoot 'bin' 'schema.json') "$env:SCOOP_HOME\schema.json" -Force
. "$env:SCOOP_HOME\test\Import-Bucket-Tests.ps1"
Move-Item "$env:SCOOP_HOME\schema.json.bak" "$env:SCOOP_HOME\schema.json" -Force
