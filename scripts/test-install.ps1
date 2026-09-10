#!/usr/bin/env pwsh
#Requires -Version 7
$ErrorActionPreference = 'Stop'
$repoDir = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "agent-skills-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $testRoot | Out-Null
$installer = Join-Path $repoDir 'install.ps1'
$lf = [string][char]10

function Assert {
  param([bool] $Condition, [string] $Message)
  if (-not $Condition) { throw "Assertion failed: $Message" }
}
function Assert-Link {
  param([string] $Path, [string] $Target)
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  Assert ($null -ne $item -and [bool]$item.LinkType -and $item.LinkTarget -eq $Target) "$Path links to $Target"
}
function Assert-Payload {
  param([string] $Path, [string] $Profile, [bool] $Copilot)
  $expected = '<!-- Managed by agent-skills; rerun the installer to update. -->' + $lf + $lf
  if ($Copilot) { $expected = (@('---', 'applyTo: "**"', '---') -join $lf) + $lf + $expected }
  $expected += [IO.File]::ReadAllText((Join-Path $repoDir "dist/instructions/$Profile.md"))
  $expected = $expected.Replace(([string][char]13 + $lf), $lf)
  Assert ([IO.File]::ReadAllText($Path) -ceq $expected) "$Path contains only common and selected policy"
}
function Assert-Throws {
  param([scriptblock] $Action)
  $failed = $false
  try { & $Action } catch { $failed = $true }
  Assert $failed 'conflicting installation is refused'
}

try {
  function Get-Excluded {
    param([string] $Profile)
    @(Get-Content -LiteralPath (Join-Path $repoDir "profiles/$Profile/excluded-skills.txt") | Where-Object { $_ })
  }
  $personalSkills = Get-Excluded work
  foreach ($agent in 'codex', 'claude', 'copilot') {
    $profile = if ($agent -eq 'copilot') { 'work' } else { 'personal' }
    $testHome = Join-Path $testRoot $agent
    $agentRoot = Join-Path $testHome ".$agent"
    $skillsRoot = Join-Path $agentRoot 'skills'
    New-Item -ItemType Directory -Force -Path $skillsRoot | Out-Null
    foreach ($retired in @('codex/start-task', 'claude/start-feature')) {
      New-Item -ItemType SymbolicLink -Path (Join-Path $skillsRoot (Split-Path -Leaf $retired)) -Target (Join-Path $repoDir $retired) | Out-Null
    }
    if ($agent -eq 'copilot') {
      foreach ($skill in $personalSkills) {
        New-Item -ItemType SymbolicLink -Path (Join-Path $skillsRoot $skill) -Target (Join-Path $repoDir "shared/$skill") | Out-Null
      }
    }
    $agentsRoot = Join-Path $agentRoot 'agents'
    New-Item -ItemType Directory -Force -Path $agentsRoot | Out-Null
    if ($agent -eq 'codex') {
      New-Item -ItemType SymbolicLink -Path (Join-Path $agentsRoot 'feature-reviewer.toml') -Target (Join-Path $repoDir 'agents/feature-reviewer.toml') | Out-Null
      $config = Join-Path $agentRoot 'config.toml'
      [IO.File]::WriteAllText($config, '[agents]' + $lf + 'max_threads = 1' + $lf)
      $originalConfig = [IO.File]::ReadAllText($config)
    }
    & $installer -Agent $agent -Profile $profile -InstallHome $testHome 6> $null
    foreach ($source in Get-ChildItem -LiteralPath (Join-Path $repoDir 'shared') -Directory) {
      $target = Join-Path $skillsRoot $source.Name
      if ($source.Name -in (Get-Excluded $profile)) {
        Assert ($null -eq (Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue)) 'no personal skill link'
      }
      else { Assert-Link $target $source.FullName }
    }
    foreach ($other in 'codex', 'claude', 'copilot', 'agents') {
      if ($other -ne $agent) { Assert (-not (Test-Path (Join-Path $testHome ".$other"))) 'only selected agent is installed' }
    }
    foreach ($name in 'start-task', 'start-feature') {
      Assert ($null -eq (Get-Item -LiteralPath (Join-Path $skillsRoot $name) -Force -ErrorAction SilentlyContinue)) 'retired launcher removed'
    }
    switch ($agent) {
      'codex' {
        $instructionFile = Join-Path $agentRoot 'AGENTS.md'
        Assert-Payload $instructionFile personal $false
        Assert-Link (Join-Path $agentRoot 'agents/feature-implementer.toml') (Join-Path $repoDir 'agents/codex/feature-implementer.toml')
        Assert-Link (Join-Path $agentRoot 'agents/feature-reviewer.toml') (Join-Path $repoDir 'dist/agents/codex/feature-reviewer.toml')
        Assert ([IO.File]::ReadAllText($config) -ceq $originalConfig) 'Codex config unchanged'
      }
      'claude' {
        $instructionFile = Join-Path $agentRoot 'CLAUDE.md'
        Assert-Payload $instructionFile personal $false
        Assert-Link (Join-Path $agentRoot 'agents/feature-implementer.md') (Join-Path $repoDir 'agents/claude/feature-implementer.md')
        Assert-Link (Join-Path $agentRoot 'agents/change-reviewer.md') (Join-Path $repoDir 'dist/agents/claude/change-reviewer.md')
      }
      'copilot' {
        $instructionFile = Join-Path $agentRoot 'instructions/agent-skills.instructions.md'
        Assert-Payload $instructionFile work $true
        Assert-Link (Join-Path $agentRoot 'agents/reviewer.agent.md') (Join-Path $repoDir 'dist/agents/copilot/reviewer.agent.md')
        Assert-Link (Join-Path $agentRoot 'agents/researcher.agent.md') (Join-Path $repoDir 'dist/agents/copilot/researcher.agent.md')
        Assert (@(Get-ChildItem -LiteralPath (Join-Path $agentRoot 'agents') -Force).Count -eq 2) 'Copilot has exactly two agents'
      }
    }
    $first = [IO.File]::ReadAllText($instructionFile)
    & $installer -Agent $agent -Profile $profile -InstallHome $testHome 6> $null
    Assert ([IO.File]::ReadAllText($instructionFile) -ceq $first) 'repeat installation is stable'
    Assert (@(Get-ChildItem -LiteralPath (Split-Path -Parent $instructionFile) -Filter '*.bak.*').Count -eq 0) 'no repeat backups'
  }

  $testHome = Join-Path $testRoot 'unmanaged'
  $instructionFile = Join-Path $testHome '.claude/CLAUDE.md'
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $instructionFile) | Out-Null
  [IO.File]::WriteAllText($instructionFile, 'User-owned instructions.')
  Assert-Throws { & $installer -Agent claude -Profile personal -InstallHome $testHome 6> $null }
  Assert (-not (Test-Path (Join-Path $testHome '.claude/skills'))) 'instruction conflict precedes links'
  & $installer -Agent claude -Profile personal -InstallHome $testHome -ReplaceInstructions 6> $null
  $backups = @(Get-ChildItem -LiteralPath (Split-Path -Parent $instructionFile) -Filter '*.bak.*')
  Assert ($backups.Count -eq 1 -and [IO.File]::ReadAllText($backups[0].FullName) -ceq 'User-owned instructions.') 'replacement preserves original'
  Assert-Payload $instructionFile personal $false

  [IO.File]::AppendAllText($instructionFile, 'Local edit.' + $lf)
  $localEdit = [IO.File]::ReadAllText($instructionFile)
  & $installer -Agent claude -Profile personal -InstallHome $testHome 6> $null
  $backups = @(Get-ChildItem -LiteralPath (Split-Path -Parent $instructionFile) -Filter '*.bak.*')
  Assert (@($backups | Where-Object { [IO.File]::ReadAllText($_.FullName) -ceq $localEdit }).Count -eq 1) 'managed edits are backed up'

  $testHome = Join-Path $testRoot 'linked-instructions'
  $instructionFile = Join-Path $testHome '.claude/CLAUDE.md'
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $instructionFile) | Out-Null
  $original = Join-Path $testRoot 'original-instructions'
  [IO.File]::WriteAllText($original, 'Linked user instructions.')
  New-Item -ItemType SymbolicLink -Path $instructionFile -Target $original | Out-Null
  Assert-Throws { & $installer -Agent claude -Profile personal -InstallHome $testHome 6> $null }
  & $installer -Agent claude -Profile personal -InstallHome $testHome -ReplaceInstructions 6> $null
  Assert (-not (Get-Item -LiteralPath $instructionFile).LinkType) 'replacement is a regular file'
  Assert ([IO.File]::ReadAllText($original) -ceq 'Linked user instructions.') 'linked source is preserved'
  $backups = @(Get-ChildItem -LiteralPath (Split-Path -Parent $instructionFile) -Filter '*.bak.*')
  Assert ($backups.Count -eq 1 -and [IO.File]::ReadAllText($backups[0].FullName) -ceq 'Linked user instructions.') 'linked instructions are backed up'
  Assert-Payload $instructionFile personal $false

  $testHome = Join-Path $testRoot 'generic'
  Assert-Throws { & $installer -Agent claude -Profile '' -InstallHome $testHome 6> $null }
  Assert-Throws { & $installer -Agent claude -Profile other -InstallHome $testHome 6> $null }
  Assert (-not (Test-Path $testHome)) 'missing or unknown profile installs nothing'
  & $installer -Agent claude -Profile personal -InstallHome $testHome 6> $null
  Assert-Link (Join-Path $testHome '.claude/skills/devshell-preflight') (Join-Path $repoDir 'shared/devshell-preflight')
  & $installer -Agent claude -Profile generic -InstallHome $testHome 6> $null
  Assert-Payload (Join-Path $testHome '.claude/CLAUDE.md') generic $false
  foreach ($source in Get-ChildItem -LiteralPath (Join-Path $repoDir 'shared') -Directory) {
    $target = Join-Path $testHome ".claude/skills/$($source.Name)"
    if ($source.Name -in (Get-Excluded generic)) {
      Assert ($null -eq (Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue)) 'excluded skill retired on profile switch'
    }
    else { Assert-Link $target $source.FullName }
  }
  & $installer -Agent copilot -Profile generic -InstallHome $testHome 6> $null
  Assert-Payload (Join-Path $testHome '.copilot/instructions/agent-skills.instructions.md') generic $true
  Assert-Link (Join-Path $testHome '.copilot/skills/warp-skill-doctor') (Join-Path $repoDir 'shared/warp-skill-doctor')

  $testHome = Join-Path $testRoot 'foreign'
  $foreign = Join-Path $testHome '.copilot/skills/devshell-preflight'
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $foreign) | Out-Null
  $foreignTarget = "$repoDir-foreign/devshell-preflight"
  New-Item -ItemType SymbolicLink -Path $foreign -Target $foreignTarget | Out-Null
  Assert-Throws { & $installer -Agent copilot -Profile work -InstallHome $testHome 6> $null }
  Assert-Link $foreign $foreignTarget

  Write-Host 'PowerShell installer isolation, migration, and repeat-run tests passed.'
}
finally {
  Remove-Item -Recurse -Force -LiteralPath $testRoot -ErrorAction SilentlyContinue
}
