# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Project

This is a Scoop bucket (sdoog) — a collection of JSON manifests for installing Windows software via [Scoop](https://scoop.sh/). It is an aggressive-persistence companion bucket to the main ScoopInstaller repos.

## Code Style

**Read [CONTRIBUTING.md](CONTRIBUTING.md) before writing or modifying any manifest.** It contains mandatory rules and non-obvious patterns (junction persistence, admin checks, registry imports, embedded script conventions, etc.). Also follow the upstream [Scoop Contributing Guide](https://github.com/ScoopInstaller/.github/blob/main/.github/CONTRIBUTING.md#for-scoop-buckets).

Key rules from CONTRIBUTING.md:

- Use portable versions when possible; `persist` program data
- Never use absolute paths — use Scoop variables (`$dir`, `$persist_dir`, `$global`) or `$env:` system variables
- Files created during install must be deleted during uninstall
- Kill auto-update processes; prefer blocking updates over allowing background updaters
- Junction links require `[System.IO.Directory]::Delete()` — `Remove-Item` does not work on junctions
- If admin rights are needed, check with `is_admin` and gate with `if ($global -and !(is_admin))` at the top of `post_install`
- Use `bin\utils.ps1` helpers: `New-PersistDirectory`, `Remove-Junction`, `Stop-App`, `Set-RegValue`, `Invoke-Download`, etc.

## Commands

```powershell
# Check version and force update a manifest
.\bin\checkver.ps1 -App <name> -ForceUpdate

# Run tests
.\Scoop-Bucket.Tests.ps1

# Format a manifest JSON
.\bin\formatjson.ps1 <name>

# Convert a PS1 script block to JSON array (for embedding in manifests)
Get-Content .\script.ps1 | ConvertTo-Json

# Read a manifest's installer script in PowerShell
(Get-Content .\bucket\<name>.json | ConvertFrom-Json).installer.script
```

## Structure

- `bucket/` — JSON manifests (one per app)
- `bin/` — PowerShell utilities (`utils.ps1`, `checkver.ps1`, `WinGet.psm1`, `WebDriver.psm1`, etc.)
- `scripts/` — Helper scripts
- `deprecated/` — Retired manifests
