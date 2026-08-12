#!/usr/bin/env pwsh
#Requires -Version 7
# PowerShell installer for platforms without a POSIX shell (mainly Windows).
# ponytail: no copied-install migration or backup logic here — legacy copied
# installs only ever existed on Unix, where install.sh handles them.
$ErrorActionPreference = 'Stop'

$repoDir = $PSScriptRoot
$homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }

$codexSkills = Join-Path $homeDir '.codex/skills'
$claudeSkills = Join-Path $homeDir '.claude/skills'
$copilotSkills = Join-Path $homeDir '.copilot/skills'
$genericSkills = Join-Path $homeDir '.agents/skills'
$agentTarget = Join-Path $homeDir '.codex/agents'
$claudeAgentTarget = Join-Path $homeDir '.claude/agents'
$configFile = Join-Path $homeDir '.codex/config.toml'

function New-Link {
  param([string] $Source, [string] $Target)

  $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
  if ($item) {
    if (-not $item.LinkType) {
      throw "Refusing conflicting destination: $Target"
    }
    if ($item.LinkTarget -eq $Source) { return }
    if ($item.LinkTarget -like "$repoDir*") {
      Remove-Item -LiteralPath $Target
      Write-Host "Removed link to moved skill: $Target -> $($item.LinkTarget)"
    }
    else {
      throw "Refusing conflicting symlink: $Target"
    }
  }

  try {
    New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
  }
  catch {
    throw "Failed to create symlink: $Target. On Windows, enable Developer Mode or run as Administrator. ($_)"
  }
  Write-Host "Linked: $Target -> $Source"
}

function Install-Skills {
  param([string] $SourceRoot, [string] $TargetRoot)

  if (-not (Test-Path -LiteralPath $SourceRoot)) { return }
  New-Item -ItemType Directory -Force -Path $TargetRoot | Out-Null
  foreach ($source in Get-ChildItem -LiteralPath $SourceRoot -Directory) {
    if (Test-Path -LiteralPath (Join-Path $source.FullName 'SKILL.md')) {
      New-Link $source.FullName (Join-Path $TargetRoot $source.Name)
    }
  }
}

# Port of install.sh render_config: ensure [agents] max_threads >= 4 and
# max_depth >= 2 while preserving every other line.
function Get-RenderedConfig {
  param([string[]] $Lines)

  $out = [System.Collections.Generic.List[string]]::new()
  $seenAgents = $false
  $inAgents = $false
  $threads = $false
  $depth = $false

  foreach ($line in $Lines) {
    if ($line -match '^\[agents\]\s*(#.*)?$') {
      if ($seenAgents) { throw 'Duplicate [agents] table is unsupported' }
      $seenAgents = $true
      $inAgents = $true
      $out.Add($line)
      continue
    }
    if ($line -match '^\s*(\[\[.*\]\]|\[[^\]]+\])\s*(#.*)?$') {
      if ($inAgents) {
        if (-not $threads) { $out.Add('max_threads = 4') }
        if (-not $depth) { $out.Add('max_depth = 2') }
      }
      $inAgents = $false
      $out.Add($line)
      continue
    }
    if ($inAgents -and $line -match '^\s*max_threads\s*=') {
      if ($threads -or $line -notmatch '^\s*max_threads\s*=\s*(\d+)\s*(#.*)?$') {
        throw 'Unsupported agents.max_threads definition'
      }
      $threads = $true
      if ([int]$Matches[1] -lt 4) { $line = [regex]::new('\d+').Replace($line, '4', 1) }
      $out.Add($line)
      continue
    }
    if ($inAgents -and $line -match '^\s*max_depth\s*=') {
      if ($depth -or $line -notmatch '^\s*max_depth\s*=\s*(\d+)\s*(#.*)?$') {
        throw 'Unsupported agents.max_depth definition'
      }
      $depth = $true
      if ([int]$Matches[1] -lt 2) { $line = [regex]::new('\d+').Replace($line, '2', 1) }
      $out.Add($line)
      continue
    }
    $out.Add($line)
  }

  if ($inAgents) {
    if (-not $threads) { $out.Add('max_threads = 4') }
    if (-not $depth) { $out.Add('max_depth = 2') }
  }
  if (-not $seenAgents) {
    if ($out.Count -gt 0) { $out.Add('') }
    $out.Add('[agents]')
    $out.Add('max_threads = 4')
    $out.Add('max_depth = 2')
  }
  return $out
}

function Update-CodexConfig {
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $configFile) | Out-Null

  $existing = @()
  if (Test-Path -LiteralPath $configFile) {
    $item = Get-Item -LiteralPath $configFile -Force
    if ($item.PSIsContainer -or $item.LinkType) {
      throw "Refusing non-regular Codex config: $configFile"
    }
    $existing = @(Get-Content -LiteralPath $configFile)
  }

  $rendered = @(Get-RenderedConfig $existing)
  if (($rendered -join "`n") -eq ($existing -join "`n")) { return }

  if (Test-Path -LiteralPath $configFile) {
    $backup = "$configFile.bak.$(Get-Date -Format yyyyMMddHHmmss)"
    if (Test-Path -LiteralPath $backup) { $backup = "$backup.$PID" }
    Copy-Item -LiteralPath $configFile -Destination $backup
    Write-Host "Backed up Codex config: $backup"
  }
  Set-Content -LiteralPath $configFile -Value ($rendered -join "`n")
  Write-Host "Updated Codex agent limits: $configFile"
}

New-Item -ItemType Directory -Force -Path $agentTarget, $claudeAgentTarget | Out-Null
Install-Skills (Join-Path $repoDir 'codex') $codexSkills
Install-Skills (Join-Path $repoDir 'claude') $claudeSkills
Install-Skills (Join-Path $repoDir 'shared') $codexSkills
Install-Skills (Join-Path $repoDir 'shared') $claudeSkills
Install-Skills (Join-Path $repoDir 'shared') $copilotSkills
Install-Skills (Join-Path $repoDir 'generic') $genericSkills

foreach ($source in Get-ChildItem -Path (Join-Path $repoDir 'agents') -Filter '*.toml' -File) {
  New-Link $source.FullName (Join-Path $agentTarget $source.Name)
}
foreach ($source in Get-ChildItem -Path (Join-Path $repoDir 'claude-agents') -Filter '*.md' -File) {
  New-Link $source.FullName (Join-Path $claudeAgentTarget $source.Name)
}

Update-CodexConfig

Write-Host "Installed skills and agents from: $repoDir"
Write-Host 'Restart Codex if updated configuration is not detected immediately.'
