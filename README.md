<div align="center">
<img src="https://github.com/user-attachments/assets/18a4286e-2a15-425c-bb7f-eb238d8fcdaf" alt="XRSOFT_LOGO_ROUND_1024" width="20%" />

# 软件狗狗 Scoop Dooge

[![GitHub Actions CI Status](https://img.shields.io/github/actions/workflow/status/xrgzs/sdoog/ci.yml?style=flat-square&logo=github&label=Tests)](https://github.com/xrgzs/sdoog/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/xrgzs/sdoog.svg?style=flat-square)](https://github.com/xrgzs/sdoog/blob/master/LICENSE)
[![Target Windows 10](https://img.shields.io/badge/Target-Windows%2010-0067B8.svg?style=flat-square)](https://www.microsoft.com/en-us/windows)
[![Repo size](https://img.shields.io/github/repo-size/xrgzs/sdoog.svg?style=flat-square)](https://github.com/WuwuZiQWQ/March7th)

UNDER CONSTRUCTION...

</div>


```powershell
scoop bucket add sdoog https://github.com/xrgzs/sdoog
```


还没安装 Scoop？

```powershell
irm c.xrgzs.top/c/scoop | iex
```


## 提交贡献

以下是几点提交贡献的小提示：

1. 遵循 [Contributing Guide](https://github.com/ScoopInstaller/.github/blob/main/.github/CONTRIBUTING.md#for-scoop-buckets) 的规范提交 Pull Request，懒得看的话需要注意以下几点：

   - 不要用 Master 分支提交 Pull Request
   - 一个 Manifest 一个 Branch 一个 PR
   - 这是常规的 Pull Request 提交规范
   - 对命名没有强制性要求（己所不欲），但要能看得出改了什么

2. 此仓库为潇然系统定制版scoop打造，默认安装会添加以下仓库，请不要重复添加以下仓库已有的配置文件，除非配置文件内容不同或有特殊优化：

   ```powershell
   Name         Source
   ----         ------
   main         https://github.com/ScoopInstaller/Main
   extras       https://github.com/ScoopInstaller/Extras
   versions     https://github.com/ScoopInstaller/Versions
   nirsoft      https://github.com/ScoopInstaller/Nirsoft
   sysinternals https://github.com/niheaven/scoop-sysinternals
   php          https://github.com/ScoopInstaller/PHP
   nerd-fonts   https://github.com/matthewjberger/scoop-nerd-fonts
   nonportable  https://github.com/ScoopInstaller/Nonportable
   java         https://github.com/ScoopInstaller/Java
   games        https://github.com/Calinou/scoop-games
   abgo_bucket  https://github.com/abgox/abgo_bucket.git
   aki          https://github.com/akirco/aki-apps.git
   dorado       https://github.com/chawyehsu/dorado.git
   DoveBoy      https://github.com/DoveBoy/Apps.git
   scoop-zapps  https://github.com/kkzzhizhou/scoop-zapps.git
   ```

3. 确保配置文件能够正常执行 Auto Update

   - 两种测试方法：

     1. VS Code 在 JSON 配置文件下按 F5

     2. 在项目根目录执行：

        ```powershell
         .\bin\checkver.ps1 -App 软件名称 -Update
        ```

   - 可以先破坏要更新的内容，然后本地执行检测操作，确保配置文件能用且为最新版本

4. 提交 PR 时，清空默认的提交内容，加入你认为有用的信息

5. 提交 PR 后，如果有更改，在 PR 中评论 `/verify`

