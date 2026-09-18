#!/usr/bin/env bash
# prompt-engineering installer for Linux and macOS (bash 3.2 compatible).
# Copies skills/<name>/SKILL.md into the skill folders of 17 coding agents.
#
# Usage:
#   ./install.sh [--global|--project] [--dir PATH] [--agent a,b] [--skill n,m]
#   ./install.sh --list
#   ./install.sh --doctor [--global|--project] [--dir PATH]
#   ./install.sh --uninstall [--global|--project] [--dir PATH]
#   ./install.sh --dry-run [--global|--project]
#   ./install.sh show <skill-name>   (print as plain prompt, pipe it anywhere)
#
# Remote install without cloning:
#   git clone --depth 1 https://github.com/ckyong826/prompt-engineering.git
#   cd prompt-engineering && ./install.sh --global
set -u

REPO_URL="https://github.com/ckyong826/prompt-engineering.git"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_ROOT="$SCRIPT_DIR"
ALL_AGENTS="agents claude-code cursor codex opencode gemini-cli github-copilot windsurf kilocode roo kiro trae goose droid antigravity clawdbot neovate"

# project path / global path per agent key
agent_project() {
  case "$1" in
    agents) echo ".agents/skills" ;;
    claude-code) echo ".claude/skills" ;;
    cursor) echo ".cursor/skills" ;;
    codex) echo ".codex/skills" ;;
    opencode) echo ".opencode/skills" ;;
    gemini-cli) echo ".gemini/skills" ;;
    github-copilot) echo ".github/skills" ;;
    windsurf) echo ".windsurf/skills" ;;
    kilocode) echo ".kilocode/skills" ;;
    roo) echo ".roo/skills" ;;
    kiro) echo ".kiro/skills" ;;
    trae) echo ".trae/skills" ;;
    goose) echo ".goose/skills" ;;
    droid) echo ".factory/skills" ;;
    antigravity) echo ".agent/skills" ;;
    clawdbot) echo "skills" ;;
    neovate) echo ".neovate/skills" ;;
    *) echo "" ;;
  esac
}

agent_global() {
  case "$1" in
    agents) echo "$HOME/.agents/skills" ;;
    claude-code) echo "$HOME/.claude/skills" ;;
    cursor) echo "$HOME/.cursor/skills" ;;
    codex) echo "$HOME/.codex/skills" ;;
    opencode) echo "$HOME/.config/opencode/skills" ;;
    gemini-cli) echo "$HOME/.gemini/skills" ;;
    github-copilot) echo "$HOME/.copilot/skills" ;;
    windsurf) echo "$HOME/.codeium/windsurf/skills" ;;
    kilocode) echo "$HOME/.kilocode/skills" ;;
    roo) echo "$HOME/.roo/skills" ;;
    kiro) echo "$HOME/.kiro/skills" ;;
    trae) echo "$HOME/.trae/skills" ;;
    goose) echo "$HOME/.config/goose/skills" ;;
    droid) echo "$HOME/.factory/skills" ;;
    antigravity) echo "$HOME/.gemini/antigravity/skills" ;;
    clawdbot) echo "$HOME/.clawdbot/skills" ;;
    neovate) echo "$HOME/.neovate/skills" ;;
    *) echo "" ;;
  esac
}

CMD="install"
SCOPE="global"
TARGET_DIR=""
WANT_AGENTS="all"
WANT_SKILLS="all"
DRY_RUN=0
SHOWNAME=""

while [ $# -gt 0 ]; do
  case "$1" in
    install|--install) CMD="install"; shift ;;
    list|--list) CMD="list"; shift ;;
    doctor|--doctor) CMD="doctor"; shift ;;
    uninstall|--uninstall) CMD="uninstall"; shift ;;
    show|--show) CMD="show"; SHOWNAME="$2"; shift 2 ;;
    --global) SCOPE="global"; shift ;;
    --project) SCOPE="project"; shift ;;
    --dir) TARGET_DIR="$2"; SCOPE="project"; shift 2 ;;
    --agent) WANT_AGENTS="$2"; shift 2 ;;
    --skill) WANT_SKILLS="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --source) SRC_ROOT="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# normalize comma lists to space lists
WANT_AGENTS="$(echo "$WANT_AGENTS" | tr ',' ' ')"
WANT_SKILLS="$(echo "$WANT_SKILLS" | tr ',' ' ')"

if [ ! -d "$SRC_ROOT/skills" ]; then
  echo "Cannot find skills/ under $SRC_ROOT. Run from the repo root or pass --source <path>." >&2
  exit 1
fi

# bundled skills = dirs containing SKILL.md
BUNDLED=""
for d in "$SRC_ROOT"/skills/*/; do
  n="$(basename "$d")"
  if [ -f "$SRC_ROOT/skills/$n/SKILL.md" ]; then
    BUNDLED="$BUNDLED $n"
  fi
done
BUNDLED="$(echo "$BUNDLED" | tr ' ' '\n' | sort | tr '\n' ' ')"

if [ "$WANT_AGENTS" = "all" ]; then WANT_AGENTS="$ALL_AGENTS"; fi
if [ "$WANT_SKILLS" = "all" ]; then WANT_SKILLS="$BUNDLED"; fi

# validate
for a in $WANT_AGENTS; do
  if [ -z "$(agent_project "$a")" ]; then echo "Unknown agent: $a" >&2; exit 1; fi
done
for s in $WANT_SKILLS; do
  if [ ! -f "$SRC_ROOT/skills/$s/SKILL.md" ]; then echo "Unknown skill: $s" >&2; exit 1; fi
done

# print one skill as a plain prompt (stdout only, pipe-friendly)
if [ "$CMD" = "show" ]; then
  if [ -z "$SHOWNAME" ]; then echo "Usage: $0 show <skill-name>" >&2; exit 1; fi
  found=""
  for s in $BUNDLED; do
    if [ "$s" = "$SHOWNAME" ]; then found="$s"; break; fi
  done
  if [ -z "$found" ]; then
    low="$(echo "$SHOWNAME" | tr 'A-Z' 'a-z')"
    for s in $BUNDLED; do
      if [ "$(echo "$s" | tr 'A-Z' 'a-z')" = "$low" ]; then found="$s"; break; fi
    done
  fi
  if [ -z "$found" ]; then echo "Unknown skill: $SHOWNAME" >&2; exit 1; fi
  if [ -f "$SRC_ROOT/prompts/$found.md" ]; then cat "$SRC_ROOT/prompts/$found.md"; exit 0; fi
  f="$SRC_ROOT/skills/$found/SKILL.md"
  if [ "$(head -c 3 "$f" | od -An -tx1 | tr -d ' \n')" = "efbbbf" ]; then
    tail -c +4 "$f"
  else
    cat "$f"
  fi | awk 'NR==1 && $0=="---" {skip=1; next} skip && $0=="---" {skip=0; next} !skip {print}'
  exit 0
fi

base_for() {
  if [ "$SCOPE" = "global" ]; then
    agent_global "$1"
  elif [ -n "$TARGET_DIR" ]; then
    echo "$TARGET_DIR/$(agent_project "$1")"
  else
    echo "$(pwd)/$(agent_project "$1")"
  fi
}

if [ "$CMD" = "list" ]; then
  echo "Skills:$BUNDLED"
  echo "Commands:"
  for f in "$SRC_ROOT"/.opencode/commands/*.md; do
    [ -e "$f" ] || continue
    echo "  - /$(basename "$f" .md)"
  done
  echo "Prompt files:"
  for s in $BUNDLED; do
    if [ -f "$SRC_ROOT/prompts/$s.md" ]; then
      echo "  - prompts/$s.md"
    else
      echo "  - prompts/$s.md (missing)"
    fi
  done
  echo "Agents: $ALL_AGENTS"
  exit 0
fi

if [ "$CMD" = "doctor" ]; then
  for a in $WANT_AGENTS; do
    base="$(base_for "$a")"
    for s in $WANT_SKILLS; do
      if [ -f "$base/$s/SKILL.md" ]; then
        echo "[OK] $a / $s $base/$s"
      else
        echo "[--] $a / $s $base/$s"
      fi
    done
  done
  exit 0
fi

DONE=0
for a in $WANT_AGENTS; do
  base="$(base_for "$a")"
  for s in $WANT_SKILLS; do
    src="$SRC_ROOT/skills/$s"
    dest="$base/$s"
    if [ "$CMD" = "uninstall" ]; then
      if [ ! -d "$dest" ]; then echo "[--] missing $dest"; continue; fi
      if [ "$DRY_RUN" = "1" ]; then echo "[dry-run] remove $dest"; continue; fi
      rm -rf "$dest"
      echo "[OK] removed $dest"
      DONE=$((DONE + 1))
      continue
    fi
    if [ "$DRY_RUN" = "1" ]; then echo "[dry-run] skill [$a] $src -> $dest"; continue; fi
    mkdir -p "$dest"
    cp -R "$src/." "$dest/"
    echo "[OK] skill [$a] -> $dest"
    DONE=$((DONE + 1))
  done
  if [ "$a" = "opencode" ] && [ "$CMD" = "install" ]; then
    if [ "$SCOPE" = "global" ]; then cbase="$HOME/.config/opencode/commands"
    elif [ -n "$TARGET_DIR" ]; then cbase="$TARGET_DIR/.opencode/commands"
    else cbase="$(pwd)/.opencode/commands"
    fi
    for f in "$SRC_ROOT"/.opencode/commands/*.md; do
      [ -e "$f" ] || continue
      if [ "$DRY_RUN" = "1" ]; then echo "[dry-run] command [opencode] $f -> $cbase/$(basename "$f")"; continue; fi
      mkdir -p "$cbase"
      cp "$f" "$cbase/"
      echo "[OK] command [opencode] -> $cbase/$(basename "$f")"
      DONE=$((DONE + 1))
    done
  fi
  if [ "$a" = "opencode" ] && [ "$CMD" = "uninstall" ]; then
    if [ "$SCOPE" = "global" ]; then cbase="$HOME/.config/opencode/commands"
    elif [ -n "$TARGET_DIR" ]; then cbase="$TARGET_DIR/.opencode/commands"
    else cbase="$(pwd)/.opencode/commands"
    fi
    for f in "$SRC_ROOT"/.opencode/commands/*.md; do
      [ -e "$f" ] || continue
      dest="$cbase/$(basename "$f")"
      [ -f "$dest" ] || continue
      if [ "$DRY_RUN" = "1" ]; then echo "[dry-run] remove $dest"; continue; fi
      rm -f "$dest"
      echo "[OK] removed $dest"
      DONE=$((DONE + 1))
    done
  fi
done

if [ "$DRY_RUN" = "0" ]; then
  if [ "$CMD" = "uninstall" ]; then echo "$DONE item(s) removed."
  else echo "$DONE item(s) installed ($SCOPE). Restart your agent to pick them up."; fi
fi
