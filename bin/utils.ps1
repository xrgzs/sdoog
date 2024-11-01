
function Get-LanzouList {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $Uri
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
    $body = $body -join "&"
    $list = Invoke-RestMethod -Uri "https://www.lanzoui.com$ajaxm" -Method Post -Body $body
    return $list.text
}


