#!/usr/bin/env pwsh
#Requires -Version 7
param(
  [Parameter(Mandatory, Position = 0)]
  [ValidateSet('codex', 'claude', 'copilot')]
  [string] $Agent,
  [ValidateNotNullOrEmpty()]
  [string] $InstallHome,
  [switch] $ReplaceInstructions
)
$ErrorActionPreference = 'Stop'
$Agent = $Agent.ToLowerInvariant()
$repoDir = $PSScriptRoot
$repoPrefix = $repoDir + [IO.Path]::DirectorySeparatorChar
$customHome = $PSBoundParameters.ContainsKey('InstallHome')
if (-not $customHome) {
  $InstallHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
}
$agentRoot = Join-Path $InstallHome ".$Agent"
$profile = 'personal'
$agentSource = $null
switch ($Agent) {
  'codex' {
    if (-not $customHome -and $env:CODEX_HOME) { $agentRoot = $env:CODEX_HOME }
    $instructionFile = Join-Path $agentRoot 'AGENTS.md'
    $agentSource = Join-Path $repoDir 'agents'
  }
  'claude' {
    $instructionFile = Join-Path $agentRoot 'CLAUDE.md'
    $agentSource = Join-Path $repoDir 'claude-agents'
  }
  'copilot' {
    $profile = 'work'
    $instructionFile = Join-Path $agentRoot 'instructions/agent-skills.instructions.md'
  }
}

$lf = [string][char]10
$marker = '<!-- Managed by agent-skills; rerun the installer to update. -->'
$rendered = $marker + $lf + $lf
if ($Agent -eq 'copilot') {
  $rendered = (@('---', 'applyTo: "**"', '---') -join $lf) + $lf + $rendered
}
$rendered += [IO.File]::ReadAllText((Join-Path $repoDir 'instructions/common.md')) + $lf
$rendered += [IO.File]::ReadAllText((Join-Path $repoDir "instructions/$profile.md"))
# Normalize source checkout line endings, including Windows Git checkouts.
$rendered = $rendered.Replace(([string][char]13 + $lf), $lf)

# Check instructions before changing installation links.
$instructionItem = Get-Item -LiteralPath $instructionFile -Force -ErrorAction SilentlyContinue
if ($instructionItem) {
  if ($instructionItem.PSIsContainer -or -not (Test-Path -LiteralPath $instructionFile -PathType Leaf)) {
    throw "Refusing non-file instructions: $instructionFile"
  }
  $managed = @(Get-Content -LiteralPath $instructionFile) -contains $marker
  if (-not $ReplaceInstructions -and ($instructionItem.LinkType -or -not $managed)) {
    throw "Refusing unmanaged instructions: $instructionFile. Use -ReplaceInstructions to back up and replace them."
  }
}

function Remove-OwnedLink {
  param([string] $Path)
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  if (-not $item) { return }
  if ($item.LinkType -eq 'HardLink') {
    Remove-Item -LiteralPath $Path
    Write-Host "Removed retired link: $Path"
    return
  }
  if ($item.LinkType -and $item.LinkTarget.StartsWith($repoPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    Remove-Item -LiteralPath $Path
    Write-Host "Removed retired link: $Path"
    return
  }
  throw "Refusing unmanaged retired entry: $Path. Review and remove it manually."
}

function New-AgentLink {
  param([string] $Source, [string] $Target)
  $isContainer = Test-Path -LiteralPath $Source -PathType Container
  $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
  if ($item) {
    if ($item.LinkType -eq 'HardLink') {
      if ((Get-FileHash -LiteralPath $Target).Hash -eq (Get-FileHash -LiteralPath $Source).Hash) { return }
      Remove-Item -LiteralPath $Target
    }
    elseif ($item.LinkType) {
      if ($item.LinkTarget -eq $Source) { return }
      if (-not $item.LinkTarget.StartsWith($repoPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing conflicting symlink: $Target"
      }
      Remove-Item -LiteralPath $Target
    }
    elseif (-not $item.PSIsContainer -and (Test-Path -LiteralPath $Source -PathType Leaf) -and
      (Get-FileHash -LiteralPath $Target).Hash -eq (Get-FileHash -LiteralPath $Source).Hash) {
      Remove-Item -LiteralPath $Target
    }
    else {
      throw "Refusing conflicting destination: $Target"
    }
  }
  try {
    New-Item -ItemType SymbolicLink -Path $Target -Target $Source -ErrorAction Stop | Out-Null
    Write-Host "Linked: $Target -> $Source"
    return
  }
  catch {
    # Unprivileged Windows accounts can't create symlinks without Developer Mode.
    # Junctions (dirs) and hard links (files) need no privilege and work on the same volume.
  }
  try {
    if ($isContainer) {
      New-Item -ItemType Junction -Path $Target -Target $Source -ErrorAction Stop | Out-Null
    }
    else {
      New-Item -ItemType HardLink -Path $Target -Target $Source -ErrorAction Stop | Out-Null
    }
  }
  catch {
    throw "Failed to link: $Target. On Windows, enable Developer Mode, use an authorized administrator shell, or ensure $InstallHome is on the same volume as $repoDir (required for the junction/hard-link fallback). ($_)"
  }
  Write-Host "Linked: $Target -> $Source"
}

$skillsRoot = Join-Path $agentRoot 'skills'
New-Item -ItemType Directory -Force -Path $skillsRoot | Out-Null
Remove-OwnedLink (Join-Path $skillsRoot 'start-task')
Remove-OwnedLink (Join-Path $skillsRoot 'start-feature')
$personalSkills = @(Get-Content -LiteralPath (Join-Path $repoDir 'instructions/personal-skills.txt'))
if ($profile -eq 'work') {
  foreach ($skill in $personalSkills) {
    if ($skill) { Remove-OwnedLink (Join-Path $skillsRoot $skill) }
  }
}
foreach ($root in 'shared', 'generic', $Agent) {
  $sourceRoot = Join-Path $repoDir $root
  if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) { continue }
  foreach ($source in Get-ChildItem -LiteralPath $sourceRoot -Directory) {
    if (-not (Test-Path -LiteralPath (Join-Path $source.FullName 'SKILL.md'))) { continue }
    if ($profile -eq 'work' -and $source.Name -in $personalSkills) { continue }
    New-AgentLink $source.FullName (Join-Path $skillsRoot $source.Name)
  }
}
if ($agentSource) {
  $agentsRoot = Join-Path $agentRoot 'agents'
  New-Item -ItemType Directory -Force -Path $agentsRoot | Out-Null
  if ($Agent -eq 'codex') {
    foreach ($name in 'task-orchestrator.toml', 'prompt-validator.toml', 'agents-md-author.toml') {
      Remove-OwnedLink (Join-Path $agentsRoot $name)
    }
  }
  foreach ($source in Get-ChildItem -LiteralPath $agentSource -File) {
    New-AgentLink $source.FullName (Join-Path $agentsRoot $source.Name)
  }
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $instructionFile) | Out-Null
if ($instructionItem.LinkType -or -not (Test-Path -LiteralPath $instructionFile) -or [IO.File]::ReadAllText($instructionFile) -cne $rendered) {
  if ($instructionItem) {
    $backup = "$instructionFile.bak.$([guid]::NewGuid().ToString('N'))"
    Copy-Item -LiteralPath $instructionFile -Destination $backup
    Remove-Item -LiteralPath $instructionFile
    Write-Host "Backed up instructions: $backup"
  }
  [IO.File]::WriteAllText($instructionFile, $rendered, [Text.UTF8Encoding]::new($false))
}
Write-Host "Installed $Agent with common + $profile instructions: $instructionFile"
Write-Host 'Restart the agent or open a new chat to reload instructions.'
