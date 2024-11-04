function Install-SQLite {
    param (
        [string]$Version = '1.0.118'
    )
    Write-Host "Downloading SQLite $Version..." -ForegroundColor DarkYellow
    $sqlitePkgPath = Join-Path $env:TEMP "SQLite_pwsh.zip"
    $sqliteTempPath = Join-Path $env:TEMP "SQLite_pwsh"
    $sqlitePath = Join-Path $PSScriptRoot "SQLite"
    Invoke-WebRequest -Uri "https://api.nuget.org/v3-flatcontainer/stub.system.data.sqlite.core.netframework/$version/stub.system.data.sqlite.core.netframework.$version.nupkg" -OutFile $sqlitePkgPath
    Write-Host "Extracting SQLite $Version..." -ForegroundColor DarkYellow -NoNewline
    Expand-Archive -Path $sqlitePkgPath -DestinationPath $sqliteTempPath -Force
    New-Item -Path $sqlitePath -ItemType Directory -Force | Out-Null
    Move-Item -Path "$sqliteTempPath\build\net451\*", "$sqliteTempPath\lib\net451\System.Data.SQLite.dll" -Destination $sqlitePath -Force
    Remove-Item -Path $sqlitePkgPath, $sqliteTempPath -Recurse -Force
}

# Load SQLite assembly
$SQLitePath = Join-Path $PSScriptRoot "SQLite" "System.Data.SQLite.dll"
$SQLiteLoaded = $false
# Download SQLite NuGet package if not exist
if (-not (Test-Path $SQLitePath)) {
    Install-SQLite | Out-Null
}
try {
    Add-Type -Path $SQLitePath
    $SQLiteLoaded = $true
    Write-Debug "SQLite assembly loaded successfully!"
} catch {
    Write-Warning 'Could not find SQLite assembly. SQLite functions will not be working'
}

$SQLiteConnection = $null
$SQLiteConnectionLoaded = $false


function New-SQLiteConnection {
    <#
  .SYNOPSIS
    Initialize a new SQLite connection
  #>
    param (
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = 'Path to SQLite database file'
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    if (-not $Script:SQLiteLoaded) { throw 'SQLite assembly not loaded' }

    $Path = Resolve-Path $Path
    $Script:SQLiteConnection = [System.Data.SQLite.SQLiteConnection]::new()
    $Script:SQLiteConnection.ConnectionString = "Data Source=$Path"
    $Script:SQLiteConnection.Open()

    $Script:SQLiteConnectionLoaded = $true

    if ($Passthru) { $Script:SQLiteConnection }
}

function Get-SQLiteConnection {
    <#
  .SYNOPSIS
    Return the current SQLite connection instance
  #>
    [OutputType([System.Data.SQLite.SQLiteConnection])]
    param ()

    if (-not $Script:SQLiteConnectionLoaded) { New-SQLiteConnection @args }

    return $Script:SQLiteConnection
}

function Invoke-SQLiteQuery {
    param (
        [Parameter(Mandatory, HelpMessage = 'SQLite query command')]
        [string] $Query
    )
    # 执行查询命令
    $SQLiteCommand = $Script:SQLiteConnection.CreateCommand()
    $SQLiteCommand.CommandText = $Query
    $SQLiteReader = $SQLiteCommand.ExecuteReader()

    # 获取所有列名
    $columnNames = 0..($SQLiteReader.FieldCount - 1) | ForEach-Object { $SQLiteReader.GetName($_) }

    # 显示结果并将每一行的数据存储在一个对象中
    $results = @()
    While ($SQLiteReader.Read()) {
        # 将当前行的数据添加到数组中
        $row = @{}
        foreach ($columnName in $columnNames) {
            $ordinal = $SQLiteReader.GetOrdinal($columnName)
            $value = $SQLiteReader.GetValue($ordinal)
            $row[$columnName] = $value
        }
        $results += [PSCustomObject]$row
    }

    # 销毁资源
    $SQLiteReader.Close()
    $SQLiteReader.Dispose()
    $SQLiteCommand.Dispose()

    return $results
}
function Close-SQLiteConnection {
    <#
  .SYNOPSIS
    Close the SQLite connection instance
  #>
    try {
        if ($Script:SQLiteConnectionLoaded) {
            $Script:SQLiteConnection.Close()
            $Script:SQLiteConnection.Dispose()
            $Script:SQLiteConnectionLoaded = $false
        }
    } catch {
        Write-Host $_ -ForegroundColor Red
    }

}

# Stop connections when the module is unloading
$ExecutionContext.SessionState.Module.OnRemove += {
    Close-SQLiteConnection -ErrorAction Ignore
}

Export-ModuleMember -Function *
