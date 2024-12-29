
if ($global) {
    $registry_scope = "HKEY_LOCAL_MACHINE"
} else {
    $registry_scope = "HKEY_CURRENT_USER"
}

$instdir = $($dir -replace '\\', '\\')

@"
Windows Registry Editor Version 5.00

[$registry_scope\SOFTWARE\Classes\dingtalk]
"URL Protocol"=""

[$registry_scope\SOFTWARE\Classes\dingtalk\Shell\Open]

[$registry_scope\SOFTWARE\Classes\dingtalk\Shell\Open\Command]
@="\"$instdir\\DingtalkScheme.exe\" %1"

[$registry_scope\SOFTWARE\Classes\dingtalkscheme]
"URL Protocol"=""

[$registry_scope\SOFTWARE\Classes\dingtalkscheme\Shell\Open\Command]
@="\"$instdir\\DingtalkScheme.exe\" %1"

[$registry_scope\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\DingTalk.exe]
@="$instdir\\DingtalkLauncher.exe"
"path"="$instdir\\DingDing"

[HKEY_CURRENT_USER\SOFTWARE\DingTalk\Package]
"auto_start"=dword:00000000

[HKEY_CURRENT_USER\SOFTWARE\DingTalk\Scheme]
"钉钉"="$instdir\\DingtalkScheme.exe"

"@ | Set-Content -Path "$dir\install-dingtalk.reg" -Encoding Unicode

reg import "$dir\install-dingtalk.reg"
