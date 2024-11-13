
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

function Get-XRSoft {
    if (!$Global:XRSoft) {
        $wc = New-Object System.Net.WebClient
        $wc.Encoding = [System.Text.Encoding]::GetEncoding("GBK")
        $content = $wc.DownloadString("https://c.xrgzs.top/SoftN.ini")
        $Global:XRSoft = $content | ConvertFrom-Ini
    }
    return $Global:XRSoft
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


function ConvertFrom-Ini {
    <#
    .SYNOPSIS
      Convert INI string into ordered hashtable
    .PARAMETER InputObject
      The INI string to be converted
    .PARAMETER CommentChars
      The characters that describe a comment
      Lines starting with the characters provided will be rendered as comments
      Default: ";"
    .PARAMETER IgnoreComments
      Remove lines determined to be comments from the resulting dictionary
    .NOTES
      This code is modified from https://github.com/lipkau/PsIni under the MIT license

      The MIT License (MIT)

      Copyright (c) 2019 Oliver Lipkau

      Permission is hereby granted, free of charge, to any person obtaining a copy
      of this software and associated documentation files (the "Software"), to deal
      in the Software without restriction, including without limitation the rights
      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
      copies of the Software, and to permit persons to whom the Software is
      furnished to do so, subject to the following conditions:

      The above copyright notice and this permission notice shall be included in all
      copies or substantial portions of the Software.

      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
      SOFTWARE.
    .LINK
      https://github.com/lipkau/PsIni
    #>
    # [OutputType([ordered])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = 'The INI string to be converted')]
        [AllowEmptyString()]
        [string]
        $Content,

        [Parameter(
            HelpMessage = 'The characters that describe a comment'
        )]
        [char[]]
        $CommentChars = @(';'),

        [Parameter(
            HelpMessage = 'Remove lines determined to be comments from the resulting dictionary'
        )]
        [switch]
        $IgnoreComments
    )

    begin {
        $SectionRegex = '^\s*\[(.+)\]\s*$'
        $KeyRegex = "^\s*(.+?)\s*=\s*(['`"]?)(.*)\2\s*$"
        $CommentRegex = "^\s*[$($CommentChars -join '')](.*)$"

        # Name of the section, in case the INI string had none
        $RootSection = '_'

        $Object = [ordered]@{}
        $CommentCount = 0
    }

    process {
        $StringReader = [System.IO.StringReader]::new($Content)

        for ($Text = $StringReader.ReadLine(); $null -ne $Text; $Text = $StringReader.ReadLine()) {
            switch -Regex ($Text) {
                $SectionRegex {
                    $Section = $Matches[1]
                    $Object[$Section] = [ordered]@{}
                    $CommentCount = 0
                    continue
                }
                $CommentRegex {
                    if (-not $IgnoreComments) {
                        if (-not $Section) {
                            $Section = $RootSection
                            $Object[$Section] = [ordered]@{}
                        }
                        $Key = '#Comment' + ($CommentCount++)
                        $Value = $Matches[1]
                        $Object[$Section][$Key] = $Value
                    }
                    continue
                }
                $KeyRegex {
                    if (-not $Section) {
                        $Section = $RootSection
                        $Object[$Section] = [ordered]@{}
                    }
                    $Key = $Matches[1]
                    $Value = $Matches[3].Replace('\r', "`r").Replace('\n', "`n")
                    if ($Object[$Section][$Key]) {
                        if ($Object[$Section][$Key] -is [array]) {
                            $Object[$Section][$Key] += $Value
                        } else {
                            $Object[$Section][$Key] = @($Object[$Section][$Key], $Value)
                        }
                    } else {
                        $Object[$Section][$Key] = $Value
                    }
                    continue
                }
            }
        }

        $StringReader.Dispose()
    }

    end {
        return $Object
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

function Set-RegValue {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Path,

        [Parameter(Mandatory, Position = 1)]
        [string]
        $Name,

        [Parameter(Mandatory, Position = 2)]
        [object]
        $Value,

        [Parameter(Position = 3)]
        [ValidateSet("REG_SZ", "REG_EXPAND_SZ", "REG_MULTI_SZ", "REG_DWORD", "REG_QWORD", "REG_BINARY")]
        [string]
        $Type,

        [Parameter()]
        [switch]
        $Wow64
    )
    try {
        if ((Get-ItemPropertyValue -Path $Path -Name $Name) -ne $Value) { throw }
    } catch {
        $Path = $Path.Replace(':', '')
        $ArgumentList = @("add `"$Path`" /f /v `"$Name`" /d `"$Value`"")
        if ($Type) { $ArgumentList += "/t $Type" }
if ($Wow64) { $ArgumentList += "/reg:32" }
        Start-Process -FilePath "reg.exe" -ArgumentList $ArgumentList -Wait -Verb "RunAs" -WindowStyle Hidden
    }
}

function Enable-DevelopmentMode {
    try {
        Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowAllTrustedApps" -Value 1 -Type REG_DWORD
        Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type REG_DWORD
    } catch {
        Write-Error "This App requires enable developmoent mode to install. Failed to enable development mode. Please reinstall this App."
        exit 1
    }
}
