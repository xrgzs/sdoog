# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Project

This is a Scoop bucket (sdoog) — a collection of JSON manifests for installing Windows software via [Scoop](https://scoop.sh/). It is an aggressive-persistence companion bucket to the main ScoopInstaller repos.

## Code Style

**Read [CONTRIBUTING.md](CONTRIBUTING.md) before writing or modifying any manifest.** It contains mandatory rules and non-obvious patterns (junction persistence, admin checks, registry imports, embedded script conventions, etc.). Also follow the upstream [Scoop Contributing Guide](https://github.com/ScoopInstaller/.github/blob/main/.github/CONTRIBUTING.md#for-scoop-buckets).

## Key rules from CONTRIBUTING.md

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

## PR & Commit Standards (upstream Scoop Contributing Guide)

**Read the [upstream guide](https://github.com/ScoopInstaller/.github/blob/main/.github/CONTRIBUTING.md#for-scoop-buckets) before submitting any PR. Failure to follow these rules will result in rejection.**

### JSON formatting rules

- Follow this exact field order: `version`, `description`, `homepage`, `license`, `notes`, `depends`, `suggest`, `architecture` (`url`, `hash`), `extract_dir`, `extract_to`, `pre_install`, `installer`, `post_install`, `env_add_path`, `env_set`, `bin`, `shortcuts`, `persist`, `pre_uninstall`, `uninstaller`, `post_uninstall`, `checkver`, `autoupdate`
- Use **4-space indentation** (tab width 4)
- **Single-item arrays must be written as strings**. E.g. `"persist": "Data"` instead of `"persist": ["Data"]`
- License must be a valid SPDX identifier (<https://spdx.org/licenses>)
- If only 32bit download exists, omit `architecture`; otherwise `architecture` is mandatory
- If app is CLI-only, omit `shortcuts`; if GUI-only with no CLI args, omit `bin`

### PR body

- PR body must follow the template at [`.github/pull_request_template.md`](.github/pull_request_template.md)
- Use `Closes #XXXX` to link the issue; keep body brief and clear

### PR title format (mandatory)

| Scenario | Format |
|----------|--------|
| New manifest | `<app name>: Add version <version>` |
| Update existing manifest | `<app name>@<version>: <small description>` |
| Maintenance (non-version change) | `(chore): <small description>` |

### Commit message rules

- First line must match the PR title format
- For AI-assisted commits, always append `Co-authored-by: Codex <codex@openai.com>` trailer
- Keep subject concise (under 50 chars where possible)
- Use imperative mood

### PR submission workflow

- Create a dedicated branch per manifest (never use `master`)
- Clear the default PR body; add useful test info (steps, screenshots, CLI output)
- After submitting, immediately comment `/verify` on the PR to trigger bot verification
- If changes are made after submission, push to the same branch and comment `/verify` again
