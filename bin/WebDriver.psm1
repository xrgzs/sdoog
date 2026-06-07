function Install-WebDriver {
    <#
  .SYNOPSIS
    Download and install Selenium WebDriver NuGet package
  #>
    Write-Host "Downloading WebDriver..." -ForegroundColor DarkYellow
    $webdriverPkgPath = Join-Path $env:TEMP "WebDriver_pwsh.zip"
    $webdriverTempPath = Join-Path $env:TEMP "WebDriver_pwsh"
    $webdriverPath = Join-Path $PSScriptRoot "WebDriver"
    Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/Selenium.WebDriver" -OutFile $webdriverPkgPath
    Write-Host "Extracting WebDriver ..." -ForegroundColor DarkYellow -NoNewline
    Expand-Archive -Path $webdriverPkgPath -DestinationPath $webdriverTempPath -Force
    New-Item -Path $webdriverPath -ItemType Directory -Force | Out-Null
    Move-Item -Path "$webdriverTempPath\lib\netstandard2.0\Selenium.WebDriver.dll" -Destination "$webdriverPath\WebDriver.dll" -Force
    Move-Item -Path "$webdriverTempPath\runtimes\win\native\selenium-manager.exe" -Destination $webdriverPath -Force
    Remove-Item -Path $webdriverPkgPath, $webdriverTempPath -Recurse -Force
}

# 设置环境变量，避免启动失败
# https://www.xrgzs.top/posts/powershell-selenium
$env:SE_MANAGER_PATH = Join-Path $PSScriptRoot "WebDriver" "selenium-manager.exe"
$WebDriverPath = Join-Path $PSScriptRoot "WebDriver" "WebDriver.dll"
$WebDriverLoaded = $false
# Download WebDriver NuGet package if not exist
if (-not (Test-Path $WebDriverPath)) {
    Install-WebDriver | Out-Null
}
try {
    Add-Type -Path $WebDriverPath
    $WebDriverLoaded = $true
    Write-Debug "WebDriver assembly loaded successfully!"
} catch {
    Write-Warning 'Could not find WebDriver assembly. WebDriver functions will not be working'
}

#region Edge Driver
$EdgeDriver = $null
$EdgeDriverLoaded = $false

function New-EdgeDriver {
    <#
  .SYNOPSIS
    Initialize an Edge Driver instance
  .PARAMETER Headless
    Initialize the Edge Driver instance in headless mode, where no window pops up
  .PARAMETER ArgumentList
    Append custom running argumtents
  #>
    param (
        [Parameter(HelpMessage = 'Initialize the Edge Driver instance in headless mode, where no window pops up')]
        [switch]
        $Headless,

        [Parameter(HelpMessage = 'Append custom running argumtents')]
        [String[]]
        $ArgumentList
    )

    if (-not $Script:WebDriverLoaded) { throw 'WebDriver is not loaded' }

    $EdgeOptions = [OpenQA.Selenium.Edge.EdgeOptions]::new()
    # Disable images downloading to speed up page loading
    $EdgeOptions.AddUserProfilePreference('profile.managed_default_content_settings.images', 2)
    if ($Headless) { $EdgeOptions.AddArgument('--headless=new') }

    if ($ArgumentList) { $EdgeOptions.AddArguments($ArgumentList) }

    if (Test-Path -Path Env:\EDGEWEBDRIVER) {
        # https://github.com/actions/runner-images/blob/main/images/win/Windows2022-Readme.md
        $Script:EdgeDriver = [OpenQA.Selenium.Edge.EdgeDriver]::new($Env:EDGEWEBDRIVER, $EdgeOptions)
    } elseif (Get-Command -Name 'msedgedriver.exe' -ErrorAction SilentlyContinue) {
        $Script:EdgeDriver = [OpenQA.Selenium.Edge.EdgeDriver]::new((Get-Command -Name 'msedgedriver.exe').Path, $EdgeOptions)
    } elseif (Test-Path -Path Env:\SE_MANAGER_PATH) {
        # 使用selenium-manager自动安装msedgedriver.exe
        $Script:EdgeDriver = [OpenQA.Selenium.Edge.EdgeDriver]::new($EdgeOptions)
    } else {
        throw 'Could not find msedgedriver.exe'
    }
    $Script:EdgeDriver.Manage().Window.Size = [System.Drawing.Size]::new(1920, 1080)
    $Script:EdgeDriverLoaded = $true
}

function Get-EdgeDriver {
    <#
  .SYNOPSIS
    Return the Edge Driver instance
  #>
    [OutputType([OpenQA.Selenium.Edge.EdgeDriver])]
    param ()

    if (-not $Script:EdgeDriverLoaded) { New-EdgeDriver @args }
    return $Script:EdgeDriver
}

function Stop-EdgeDriver {
    <#
  .SYNOPSIS
    Stop the Edge Driver instance
  #>

    if ($Script:EdgeDriverLoaded) {
        $Script:EdgeDriver.Quit()
        $Script:EdgeDriverLoaded = $false
    }
}
#endregion

<#
#region Firefox Driver
# 不使用 FireFoxDriver
#endregion
#>

# Stop drivers when the module is unloading
$ExecutionContext.SessionState.Module.OnRemove += {
    Stop-EdgeDriver -ErrorAction Ignore
}

Export-ModuleMember -Function *
