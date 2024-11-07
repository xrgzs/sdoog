
function Get-LanzouList {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $Uri,
        [Parameter(Mandatory = $false, Position = 1)]
        [string]
        $Pass
    )
    $sharekey = $Uri -split '/' | Select-Object -Last 1
    $webcontent = Invoke-RestMethod -Uri "https://www.lanzoui.com/$sharekey" -UseBasicParsing
    $ajaxm = [regex]::Match($webcontent, '\/filemoreajax\.php\?file=\d+').Value
    $body = @()
    $body += "lx=2"
    $body += "fid=$([regex]::Match($webcontent, "'fid':(\w+)").Groups[1].Value)"
    $body += "uid=$([regex]::Match($webcontent, "'uid':(\w+)").Groups[1].Value)"
    $body += "pg=1"
    $body += "rep=0"
    $body += "t=$([regex]::Match($webcontent, "var $($([regex]::Match($webcontent, "'t':(\w+)").Groups[1].Value)) = '(\w+)'").Groups[1].Value)"
    $body += "k=$([regex]::Match($webcontent, "var $($([regex]::Match($webcontent, "'k':(\w+)").Groups[1].Value)) = '(\w+)'").Groups[1].Value)"
    $body += "up=1"
    if ($Pass) { $body += "pwd=$Pass" }
    $body = $body -join "&"
    $list = Invoke-RestMethod -Uri "https://www.lanzoui.com$ajaxm" -Method Post -Body $body
    return $list.text
}


function ConvertFrom-HtmlEncodedText {
    <#
    .SYNOPSIS
      Converts a string that has been HTML-encoded for HTTP transmission into a decoded string.
    .PARAMETER InputObject
      The string to be decoded
    #>
    [OutputType([string])]
    param (
        [parameter(Mandatory, ValueFromPipeline, HelpMessage = 'The string to be decoded')]
        [string]
        $InputObject
    )

    process {
        [System.Net.WebUtility]::HtmlDecode($InputObject)
    }
}


function Get-RedirectedUrl1st {
    <#
    .SYNOPSIS
      Get the first redirected URL from the given URL
    .PARAMETER Uri
      The Uniform Resource Identifier (URI) that will be redirected
    .PARAMETER UserAgent
      The user agent string for the web request
    #>
    [OutputType([string])]
    param (
        [parameter(Mandatory, ValueFromPipeline, HelpMessage = 'The URI that will be redirected')]
        [string]
        $Uri,

        [Parameter(HelpMessage = 'The user agent string for the web request')]
        [string]
        $UserAgent,

        [Parameter(HelpMessage = 'The user agent string for the web request')]
        [System.Collections.IDictionary]
        $Headers
    )

    process {
        $Request = [System.Net.WebRequest]::Create($Uri)
        if ($UserAgent) {
            $Request.UserAgent = $UserAgent
        }
        if ($Headers) {
            $Headers.GetEnumerator() | ForEach-Object -Process { $Request.Headers.Set($_.Key, $_.Value) }
        }
        $Request.AllowAutoRedirect = $false
        $Response = $Request.GetResponse()
        Write-Output -InputObject $Response.GetResponseHeader('Location')
        $Response.Close()
    }
}
function New-PersistDirectory {
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]
        $dataPath,

        [parameter(Mandatory = $true, Position = 1)]
        [string]
        $persistPath,

        [switch]
        $Migrate
    )
    # Create persist dir
    New-Item $persistPath -Type Directory -Force -ErrorAction SilentlyContinue | Out-Null
    if (Test-Path $dataPath) {
        $dataPathItem = Get-Item -Path $dataPath
        if ($dataPathItem.LinkType -eq 'Junction') {
            # Delete old Junction
            # Remove-Item regard junction as actual directory, do not use it.
            try { $dataPathItem.Delete() } catch {}
        } else {
            if ($Migrate) {
                # Migrate data
                Get-ChildItem $dataPath | ForEach-Object { Move-Item $_.FullName $persistPath -Force } | Out-Null
            }
            Remove-Item $dataPath -Force -Recurse | Out-Null
        }
    }
    # Create new Junction
    New-Item -ItemType Junction -Path $dataPath -Target $persistPath | Out-Null
}

function Remove-Junction {
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]
        $dataPath
    )
    # Delete Junction only
    $dataPathItem = Get-Item -Path $dataPath
    try { $dataPathItem.Delete() } catch {}
}

function Stop-App {
    param(
        [Parameter(Position = 0, ValueFromPipeline, HelpMessage = "Array of paths to search for executables")]
        [string[]]
        $Path
    )

    # 如果未传入 Path 参数，使用默认值
    if (-not $Path) {
        $Path = @($dir, (Split-Path $dir -Parent) + '\current')
    }

    # 获取所有进程到内存中，提高性能
    $allProcesses = Get-Process

    foreach ($app_dir in $Path) {
        $allProcesses | Where-Object {
            $_.Modules.FileName -like "$app_dir\*"
        } | ForEach-Object {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Wait-Process -Id $_.Id -ErrorAction SilentlyContinue -Timeout 30
        }
    }
}
