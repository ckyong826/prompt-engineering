<#
.SYNOPSIS
  Install prompt-engineering skills into coding agents (Windows, Linux, macOS).
.DESCRIPTION
  Copies skills/<name>/SKILL.md from this repo into the skill folders of
  17 coding agents (Claude Code, Cursor, Codex, OpenCode, Gemini CLI,
  GitHub Copilot, Windsurf, and more). Works in Windows PowerShell 5.1
  and PowerShell 7+ on Linux/macOS.
.EXAMPLE
  .\install.ps1 -Global
  Install all skills for all agents into your home directory.
.EXAMPLE
  .\install.ps1 -Project -Agent claude-code,cursor
  Install into the current project for Claude Code and Cursor only.
.EXAMPLE
  .\install.ps1 -Show autonomous-project-build-orchestrator
  Print one skill as a plain prompt (pipe it into any agent CLI).
.EXAMPLE
  .\install.ps1 -List
  Show bundled skills and supported agents.
.EXAMPLE
  powershell -NoProfile -Command "& {[scriptblock]::Create((Invoke-RestMethod https://raw.githubusercontent.com/ckyong826/prompt-engineering/main/install.ps1))} -Remote -Global"
  Install without cloning: download and install straight from GitHub.
#>
[CmdletBinding()]
param(
  [string]$Agent = "all",
  [string]$Skill = "all",
  [string]$TargetDir = "",
  [switch]$Global,
  [switch]$Project,
  [switch]$List,
  [switch]$Doctor,
  [switch]$Uninstall,
  [switch]$DryRun,
  [switch]$Remote,
  [string]$Show = "",
  [string]$RepoUrl = "https://github.com/ckyong826/prompt-engineering",
  [string]$Branch = "main",
  [string]$Source = ""
)

$ErrorActionPreference = "Stop"

function Get-AgentTable {
  # key -> @{ label, project, global } ; global uses ~ for home.
  $t = @{}
  $t["agents"]           = @{ label = "Universal (.agents)"; project = ".agents/skills";       global = "~/.agents/skills" }
  $t["claude-code"]      = @{ label = "Claude Code";         project = ".claude/skills";       global = "~/.claude/skills" }
  $t["cursor"]           = @{ label = "Cursor";              project = ".cursor/skills";       global = "~/.cursor/skills" }
  $t["codex"]            = @{ label = "Codex";               project = ".codex/skills";        global = "~/.codex/skills" }
  $t["opencode"]         = @{ label = "OpenCode";            project = ".opencode/skills";     global = "~/.config/opencode/skills" }
  $t["gemini-cli"]       = @{ label = "Gemini CLI";          project = ".gemini/skills";       global = "~/.gemini/skills" }
  $t["github-copilot"]   = @{ label = "GitHub Copilot";      project = ".github/skills";       global = "~/.copilot/skills" }
  $t["windsurf"]         = @{ label = "Windsurf";            project = ".windsurf/skills";     global = "~/.codeium/windsurf/skills" }
  $t["kilocode"]         = @{ label = "Kilo Code";           project = ".kilocode/skills";     global = "~/.kilocode/skills" }
  $t["roo"]              = @{ label = "Roo Code";            project = ".roo/skills";          global = "~/.roo/skills" }
  $t["kiro"]             = @{ label = "Kiro CLI";            project = ".kiro/skills";         global = "~/.kiro/skills" }
  $t["trae"]             = @{ label = "Trae";                project = ".trae/skills";         global = "~/.trae/skills" }
  $t["goose"]            = @{ label = "Goose";               project = ".goose/skills";        global = "~/.config/goose/skills" }
  $t["droid"]            = @{ label = "Droid";               project = ".factory/skills";      global = "~/.factory/skills" }
  $t["antigravity"]      = @{ label = "Antigravity";         project = ".agent/skills";        global = "~/.gemini/antigravity/skills" }
  $t["clawdbot"]         = @{ label = "Clawdbot";            project = "skills";               global = "~/.clawdbot/skills" }
  $t["neovate"]          = @{ label = "Neovate";             project = ".neovate/skills";      global = "~/.neovate/skills" }
  return $t
}

function Expand-Home([string]$p) {
  if ($p.StartsWith("~/") -or $p.StartsWith("~\")) { return (Join-Path $HOME $p.Substring(2)) }
  if ($p -eq "~") { return $HOME }
  return $p
}

function Resolve-SourceRoot {
  param([string]$Explicit, [switch]$UseRemote, [string]$Url, [string]$Br)
  if ($Explicit -ne "") {
    if (-not (Test-Path -LiteralPath $Explicit)) { throw "Source not found: $Explicit" }
    return (Resolve-Path -LiteralPath $Explicit).Path
  }
  $invocationPath = $MyInvocation.PSCommandPath
  if ($invocationPath -ne $null -and $invocationPath -ne "") {
    $dir = Split-Path -Parent $invocationPath
    if (Test-Path -LiteralPath (Join-Path $dir "skills")) { return $dir }
  }
  $here = (Get-Location).Path
  if (Test-Path -LiteralPath (Join-Path $here "skills")) { return $here }
  if ($UseRemote) {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("prompt-eng-" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $zip = Join-Path $tmp "repo.zip"
    $zipUrl = "$Url/archive/refs/heads/$Br.zip"
    Write-Host "Download $zipUrl ..."
    Invoke-WebRequest -Uri $zipUrl -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    $inner = Get-ChildItem -Path $tmp -Directory | Select-Object -First 1
    return $inner.FullName
  }
  throw "Cannot find skills/. Run from the repo root, pass -Source <path>, or use -Remote."
}

function Get-BundledSkills([string]$root) {
  $skillsDir = Join-Path $root "skills"
  $out = @()
  if (Test-Path -LiteralPath $skillsDir) {
    foreach ($d in (Get-ChildItem -Path $skillsDir -Directory)) {
      if (Test-Path -LiteralPath (Join-Path $d.FullName "SKILL.md")) { $out += $d.Name }
    }
  }
  return ($out | Sort-Object)
}

function Get-BundledCommands([string]$root) {
  $cmdDir = Join-Path $root (Join-Path ".opencode" "commands")
  $out = @()
  if (Test-Path -LiteralPath $cmdDir) {
    foreach ($f in (Get-ChildItem -Path $cmdDir -Filter "*.md" -File)) { $out += $f.Name }
  }
  return ($out | Sort-Object)
}

function Split-List([string]$v) {
  if ($v -eq "" -or $v -eq "all") { return $null }
  return ($v.Split(",") | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ -ne "" })
}

function Get-SkillBody([string]$root, [string]$skill) {
  $file = Join-Path $root (Join-Path "skills" (Join-Path $skill "SKILL.md"))
  $raw = Get-Content -LiteralPath $file -Raw
  $raw = $raw -replace '^\uFEFF', ''
  $m = [regex]::Match($raw, '\A---\r?\n.*?\r?\n---\r?\n?', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if ($m.Success) { $raw = $raw.Substring($m.Length) }
  return ($raw.TrimEnd() + "`n")
}

# --- main ---
$table = Get-AgentTable
$root = Resolve-SourceRoot -Explicit $Source -UseRemote:$Remote -Url $RepoUrl -Br $Branch
$allSkills = Get-BundledSkills $root
$allCommands = Get-BundledCommands $root

if ($Show -ne "") {
  $match = @($allSkills | Where-Object { $_ -eq $Show })
  if ($match.Count -eq 0) { $match = @($allSkills | Where-Object { $_.ToLowerInvariant() -eq $Show.ToLowerInvariant() }) }
  if ($match.Count -eq 0) { throw ("Unknown skill: " + $Show) }
  $pf = Join-Path $root (Join-Path "prompts" ($match[0] + ".md"))
  if (Test-Path -LiteralPath $pf) { Write-Output (Get-Content -LiteralPath $pf -Raw) }
  else { Write-Output (Get-SkillBody $root $match[0]) }
  return
}

if ($List) {
  Write-Host ("Skills (" + $allSkills.Count + "):")
  foreach ($s in $allSkills) { Write-Host ("  - " + $s) }
  Write-Host "Prompt files (prompts/):"
  foreach ($s in $allSkills) {
    $pf = Join-Path $root (Join-Path "prompts" ($s + ".md"))
    if (Test-Path -LiteralPath $pf) { Write-Host ("  - prompts/" + $s + ".md") }
    else { Write-Host ("  - prompts/" + $s + ".md (missing)") }
  }
  Write-Host ("Commands (" + $allCommands.Count + "):")
  foreach ($c in $allCommands) { Write-Host ("  - /" + $c.Replace(".md", "")) }
  Write-Host "Agents:"
  foreach ($k in ($table.Keys | Sort-Object)) {
    Write-Host ("  - " + $k + " (" + $table[$k].label + ") project=" + $table[$k].project + " global=" + $table[$k].global)
  }
  return
}

$wantedAgents = Split-List $Agent
if ($wantedAgents -eq $null) { $wantedAgents = @($table.Keys | Sort-Object) }
foreach ($a in $wantedAgents) {
  if (-not $table.ContainsKey($a)) { throw ("Unknown agent: " + $a) }
}
$wantedSkills = Split-List $Skill
if ($wantedSkills -eq $null) { $wantedSkills = @($allSkills) }
foreach ($s in $wantedSkills) {
  if ($allSkills -notcontains $s) { throw ("Unknown skill: " + $s) }
}

$useProjectBase = ""
$isGlobal = $true
if ($TargetDir -ne "") { $useProjectBase = (Resolve-Path -LiteralPath $TargetDir -ErrorAction SilentlyContinue); if ($useProjectBase -eq $null) { $useProjectBase = $TargetDir } else { $useProjectBase = $useProjectBase.Path }; $isGlobal = $false }
elseif ($Project) { $useProjectBase = (Get-Location).Path; $isGlobal = $false }

if ($Doctor) {
  if ($isGlobal) { Write-Host "Skill status (global):" } else { Write-Host ("Skill status (project " + $useProjectBase + "):") }
  foreach ($a in $wantedAgents) {
    if ($isGlobal) { $base = Expand-Home $table[$a].global } else { $base = Join-Path $useProjectBase $table[$a].project }
    foreach ($s in $wantedSkills) {
      $p = Join-Path $base $s
      if (Test-Path -LiteralPath (Join-Path $p "SKILL.md")) { Write-Host ("  [OK] " + $a + " / " + $s + " " + $p) }
      else { Write-Host ("  [--] " + $a + " / " + $s + " " + $p) }
    }
  }
  return
}

$done = 0
foreach ($a in $wantedAgents) {
  if ($isGlobal) { $base = Expand-Home $table[$a].global } else { $base = Join-Path $useProjectBase $table[$a].project }
  foreach ($s in $wantedSkills) {
    $src = Join-Path (Join-Path $root "skills") $s
    $dest = Join-Path $base $s
    if ($Uninstall) {
      if (-not (Test-Path -LiteralPath $dest)) { Write-Host ("[--] missing " + $dest); continue }
      if ($DryRun) { Write-Host ("[dry-run] remove " + $dest); continue }
      Remove-Item -LiteralPath $dest -Recurse -Force
      Write-Host ("[OK] removed " + $dest)
      $done++
      continue
    }
    if ($DryRun) { Write-Host ("[dry-run] skill [" + $a + "] " + $src + " -> " + $dest); continue }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Copy-Item -Path (Join-Path $src "*") -Destination $dest -Recurse -Force
    Write-Host ("[OK] skill [" + $a + "] -> " + $dest)
    $done++
  }
  if (($a -eq "opencode") -and (-not $Uninstall)) {
    if ($isGlobal) { $cbase = Expand-Home "~/.config/opencode/commands" } else { $cbase = Join-Path $useProjectBase (Join-Path ".opencode" "commands") }
    foreach ($c in $allCommands) {
      $csrc = Join-Path $root (Join-Path ".opencode" (Join-Path "commands" $c))
      $cdest = Join-Path $cbase $c
      if ($DryRun) { Write-Host ("[dry-run] command [opencode] " + $csrc + " -> " + $cdest); continue }
      New-Item -ItemType Directory -Path $cbase -Force | Out-Null
      Copy-Item -Path $csrc -Destination $cdest -Force
      Write-Host ("[OK] command [opencode] -> " + $cdest)
      $done++
    }
  }
  if (($a -eq "opencode") -and $Uninstall) {
    if ($isGlobal) { $cbase = Expand-Home "~/.config/opencode/commands" } else { $cbase = Join-Path $useProjectBase (Join-Path ".opencode" "commands") }
    foreach ($c in $allCommands) {
      $cdest = Join-Path $cbase $c
      if (-not (Test-Path -LiteralPath $cdest)) { continue }
      if ($DryRun) { Write-Host ("[dry-run] remove " + $cdest); continue }
      Remove-Item -LiteralPath $cdest -Force
      Write-Host ("[OK] removed " + $cdest)
      $done++
    }
  }
}

if ($DryRun) { return }
if ($Uninstall) { Write-Host ($done.ToString() + " item(s) removed.") }
else {
  if ($isGlobal) { Write-Host ($done.ToString() + " item(s) installed globally. Restart your agent to pick them up.") }
  else { Write-Host ($done.ToString() + " item(s) installed into " + $useProjectBase + ". Restart your agent to pick them up.") }
}


