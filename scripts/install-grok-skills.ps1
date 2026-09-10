#!/usr/bin/env pwsh
# Copy IcePanel C4 skills into Grok Build's user (or project) skill root.
# Canonical bodies stay in skills/; this only installs them where Grok looks.
[CmdletBinding()]
param(
    [string] $Dest,
    [switch] $Project,
    [switch] $Link,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$SkillsSrc = Join-Path $Root 'skills'

if (-not (Test-Path -LiteralPath $SkillsSrc -PathType Container)) {
    throw "skills directory not found at $SkillsSrc"
}

if ($Project) {
    $Dest = Join-Path (Get-Location) '.grok/skills'
} elseif (-not $Dest) {
    if ($env:GROK_SKILLS_DIR) {
        $Dest = $env:GROK_SKILLS_DIR
    } else {
        $grokHome = if ($env:GROK_HOME) { $env:GROK_HOME } else { Join-Path $HOME '.grok' }
        $Dest = Join-Path $grokHome 'skills'
    }
}

$skillDirs = Get-ChildItem -LiteralPath $SkillsSrc -Directory |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } |
    Sort-Object Name

if (-not $skillDirs) {
    throw "no SKILL.md files found under $SkillsSrc"
}

$installed = @()
foreach ($skillDir in $skillDirs) {
    $target = Join-Path $Dest $skillDir.Name
    $installed += $skillDir.Name

    if ($DryRun) {
        $action = if ($Link) { 'link' } else { 'copy' }
        Write-Host "dry-run: $action $($skillDir.FullName) -> $target"
        continue
    }

    New-Item -ItemType Directory -Force -Path $Dest | Out-Null
    if (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
    }

    if ($Link) {
        New-Item -ItemType SymbolicLink -Path $target -Target $skillDir.FullName | Out-Null
    } else {
        Copy-Item -LiteralPath $skillDir.FullName -Destination $target -Recurse
    }
    Write-Host "installed $($skillDir.Name) -> $target"
}

Write-Host ""
Write-Host "Grok skill root: $Dest"
Write-Host ("Skills: " + ($installed -join ' '))
Write-Host ""
Write-Host "Next:"
Write-Host "  `$env:ICEPANEL_TOKEN = '<key-id>:<secret>'   # X-API-Key only; do not commit this"
Write-Host "  grok inspect"
Write-Host "  # slash: /creating-c4-diagrams  /translating-context-maps"
