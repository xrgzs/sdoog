$DebugPreference = 'Continue'
Import-Module $(Join-Path $PSScriptRoot "SQLite.psm1")

# function Install-Yq {
#     $installers = @('scoop', 'choco', 'winget')
#     foreach ($installer in $installers) {
#         try {
#             switch ($installer) {
#                 'scoop' { scoop install main/yq }
#                 'choco' { choco install yq -y --no-progress }
#                 'winget' { winget install --id "MikeFarah.yq" --exact --source winget --accept-source-agreements --disable-interactivity --silent --accept-package-agreements --force }
#             }
#             if (Get-Command yq -ErrorAction SilentlyContinue) {
#                 return
#             }
#         } catch {
#             Write-Warning "$installer faild to install yq."
#         }
#     }
#     Write-Warning "All methods of installing yq are failed."
# }

function Install-PowerShellYaml {
    try {
        Install-Module -Name PowerShell-Yaml -Force
    } catch {
        Write-Warning "PowerShell-Yaml installation faild: $_"
    }
}

# if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
#     Write-Warning "yq has not been installed."
#     Install-Yq | Out-Null
# }

if (-not (Get-Module -ListAvailable -Name PowerShell-Yaml)) {
    Write-Warning "PowerShell-Yaml has not been installed."
    Install-PowerShellYaml | Out-Null
}

function ConvertFrom-YamlString {
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [string]
        $InputObject
    )
    # try {
    #     $OutputObject = $InputObject | yq -o xml | yq -p xml -o json | ConvertFrom-Json
    # } catch {
    #     $OutputObject = $InputObject | ConvertFrom-Yaml
    # }
    return $InputObject | ConvertFrom-Yaml
}

function ConvertFrom-MSZIP {
    <#
    .SYNOPSIS
      Convert MSZIP format to plain text
    .DESCRIPTION
      This function is used to convert MSZIP format to plain text, which can be commomly seen in WinGet manifest.
    .NOTES
      This function would return error. But it doesn't affect the output.
    .LINK
      Specify a URI to a help page, this will show when Get-Help -Online is used.
    .PARAMETER buffer
      The buffer to convert.
    .EXAMPLE
      ConvertFrom-MSZIP -buffer $buffer
    #>
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, HelpMessage = "The buffer to convert.")]
        [byte[]]$buffer
    )

    begin {
        # 在循环开始前初始化任何变量
        $magicHeader = [byte[]](0, 0, 0x43, 0x4b)
        $decompressed = [System.IO.MemoryStream]::new()
    }

    process {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        # 检查文件头是否为 MSZIP 格式
        if (-not ($buffer[26..29] -join ',') -eq ($magicHeader -join ',')) {
            throw "Invalid MSZIP format"
        }

        # 从文件头开始搜索
        $chunkIndex = 26

        # 使用提供的缓冲区创建内存流
        $bufferStream = [System.IO.MemoryStream]::new($buffer)

        # 循环搜索并解压缩每个块
        while ($chunkIndex -lt $buffer.Length) {
            $chunkIndex += $magicHeader.Length
            $bufferStream.Position = $chunkIndex
            try {
                $decompressedChunk = New-Object System.IO.Compression.DeflateStream($bufferStream, [System.IO.Compression.CompressionMode]::Decompress)
                $decompressedChunk.CopyTo($decompressed)
            } catch {
                # Write-Warning "解压错误: chunkIndex: $chunkIndex, $_"
                break
            }
            $chunkIndex++
        }
    }

    end {
        # 在所有输入处理完毕后执行清理工作
        $decompressed.Position = 0
        $reader = [System.IO.StreamReader]::new($decompressed)
        $reader.ReadToEnd()
    }
}


function Get-WinGetDatabase {
    $WorkDir = (New-Item -ItemType Directory -Path $env:TEMP -Name "WinGet_pwsh" -Force).FullName
    # 下载WinGet源安装包
    $MsixPath = Join-Path $WorkDir "source2.msix"
    Invoke-WebRequest "https://cdn.winget.microsoft.com/cache/source2.msix" -OutFile $MsixPath

    # 解压出WinGet数据库文件
    Expand-Archive -Path $MsixPath -DestinationPath $WorkDir -Force

    # 读取数据库
    $DBPath = Join-Path $WorkDir "Public\index.db"
    New-SQLiteConnection -Path $DBPath
    $results = Invoke-SQLiteQuery -Query "SELECT CAST ( rowid AS TEXT ) AS rowid, CAST ( id AS TEXT ) AS id, CAST ( name AS TEXT ) AS name, CAST ( moniker AS TEXT ) AS moniker, CAST ( latest_version AS TEXT ) AS latest_version, CAST ( hash AS BLOB ) AS hash FROM packages"
    Close-SQLiteConnection

    # 删除缓存文件
    Remove-Item -Path $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
    return $results
}

function Get-WinGetInfo {
    param (
        [string] $Id
    )
    # 获取软件信息，避免重复请求，存储为全局变量
    if (!$Global:WinGetDB) {
        Write-Warning "WinGet Database has not been loaded yet, loading now..."
        $Global:WinGetDB = Get-WinGetDatabase
    } else {
        Write-Debug "WinGet Database has been loaded already, using cache data..."
    }
    # 使用模糊匹配软件ID
    $Info = $Global:WinGetDB | Where-Object { $_.id -like "*$Id*" } | Select-Object -First 1
    if (!$Info) {
        Write-Debug "Cannot find software info for $Id, please check your input."
        throw "Cannot find software info for $Id, please check your input."
    }
    # 获取软件版本信息
    Write-Debug "Got version information: $Info"
    return $Info
}

function Get-WinGetManifest {
    param(
        [string]$Id,
        [PSCustomObject]$Info
    )
    if (!$Info) {
        $Info = Get-WinGetInfo -Id $Id
    }
    write-Debug "Getting manifest for $Info..."
    $Id = $Info.id
    $hexString = [BitConverter]::ToString($Info.hash).Replace("-", "").ToLower().Substring(0, 8)
    $versionDataUrl = "https://cdn.winget.microsoft.com/cache/packages/$Id/$hexString/versionData.mszyml"
    Write-Debug "Requesting for version data..."
    Write-Debug "versionDataUrl: $versionDataUrl"
    $buffer = (Invoke-WebRequest $versionDataUrl).Content
    Write-Debug "Converting version data from MSZIP format..."
    $versionData = (ConvertFrom-MSZIP -buffer $buffer | ConvertFrom-YamlString).vD[0]
    Write-Debug "Got informations:"
    Write-Debug "RelativePath: $($versionData.rP)"
    Write-Debug "Version:      $($versionData.v)"
    $manifestUrl = "https://cdn.winget.microsoft.com/cache/" + $versionData.rP
    Write-Debug "manifestUrl:  $manifestUrl"
    $manifest = Invoke-RestMethod $manifestUrl

    $result = $manifest | ConvertFrom-YamlString
    return $result
}


Export-ModuleMember -Function Get-WinGetInfo, Get-WinGetManifest
