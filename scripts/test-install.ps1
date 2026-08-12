#!/usr/bin/env pwsh
#Requires -Version 7
$ErrorActionPreference = 'Stop'

$repoDir = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "agent-skills-install-$PID"
$testHome = Join-Path $testRoot 'home'
New-Item -ItemType Directory -Force -Path (Join-Path $testHome '.codex') | Out-Null

function Assert {
  param([bool] $Condition, [string] $Message)
  if (-not $Condition) { throw "Assertion failed: $Message" }
}

function Assert-Link {
  param([string] $Path, [string] $Target)
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  Assert ($null -ne $item -and [bool]$item.LinkType) "$Path is a link"
  Assert ($item.LinkTarget -eq $Target) "$Path -> $Target (got $($item.LinkTarget))"
}

try {
  Set-Content -LiteralPath (Join-Path $testHome '.codex/config.toml') -Value @'
[ui]
theme = "dark"

[agents]
max_threads = 1

[[agents.roles]]
name = "reviewer"
'@

  $env:USERPROFILE = $testHome
  & (Join-Path $repoDir 'install.ps1') 6> $null

  Assert-Link (Join-Path $testHome '.codex/skills/start-task') (Join-Path $repoDir 'codex/start-task')
  Assert-Link (Join-Path $testHome '.claude/skills/start-feature') (Join-Path $repoDir 'claude/start-feature')
  foreach ($skillsRoot in '.codex/skills', '.claude/skills', '.copilot/skills') {
    foreach ($skill in 'ponytail', 'i-have-adhd', 'grill-with-docs', 'grilling', 'domain-modeling') {
      Assert-Link (Join-Path $testHome $skillsRoot $skill) (Join-Path $repoDir 'shared' $skill)
    }
  }
  Assert (-not (Test-Path (Join-Path $testHome '.claude/skills/start-task'))) 'start-task stays out of Claude skills'
  Assert (-not (Test-Path (Join-Path $testHome '.copilot/skills/start-task'))) 'start-task stays out of Copilot skills'
  Assert (-not (Test-Path (Join-Path $testHome '.codex/skills/start-feature'))) 'start-feature stays out of Codex skills'
  Assert-Link (Join-Path $testHome '.claude/agents/feature-implementer.md') (Join-Path $repoDir 'claude-agents/feature-implementer.md')
  Assert-Link (Join-Path $testHome '.codex/agents/feature-implementer.toml') (Join-Path $repoDir 'agents/feature-implementer.toml')

  $config = Get-Content -Raw -LiteralPath (Join-Path $testHome '.codex/config.toml')
  foreach ($needle in 'theme = "dark"', 'max_threads = 4', 'max_depth = 2', '[[agents.roles]]', 'name = "reviewer"') {
    Assert $config.Contains($needle) "config keeps '$needle'"
  }

  $backups = @(Get-ChildItem -Path (Join-Path $testHome '.codex') -Filter 'config.toml.bak.*')
  Assert ($backups.Count -eq 1) 'one config backup after first run'

  & (Join-Path $repoDir 'install.ps1') 6> $null
  $repeatBackups = @(Get-ChildItem -Path (Join-Path $testHome '.codex') -Filter 'config.toml.bak.*')
  Assert ($repeatBackups.Count -eq 1) 'no new backup on repeat run'

  Write-Host 'PowerShell installer test passed.'
}
finally {
  Remove-Item -Recurse -Force -Path $testRoot -ErrorAction SilentlyContinue
}
