# Prompt Engineering Library

This library stores reusable prompts for software work.
Each prompt solves one clear task in the software flow.
One source file feeds every major coding agent, as a skill or as a plain prompt.

## What Is This Library For

You use this library to build software faster and with fewer errors.
It gives you ready prompts for common engineering tasks.
Each prompt tells the AI tool what role to take and what steps to follow.
You do not need to write a long prompt from scratch.

## Skill or Prompt

Each entry ships in two forms. Both forms hold the same text.

- Use the **skill** form when your tool supports skills.
  The agent finds it by name and loads it on its own.
  Files live in `skills/<name>/SKILL.md`.
- Use the **prompt** form when your tool takes pasted text.
  Copy the file, or print it and pipe it into a CLI.
  Files live in `prompts/<name>.md`.

Rule: edit the skill file only. Then run `export` to rebuild the prompt file.
This keeps both forms in sync.

## Install

Pick one method. All three copy the same `skills/` source into your agents.

### Option 1: npm (Node 16 or newer)

No clone needed. Run from any folder.

```bash
npx @ckyong826/prompt-engineering install --global
```

Install into one project, for two agents only:

```bash
npx @ckyong826/prompt-engineering install --project --agent claude-code,cursor
```

Other commands:

```bash
npx @ckyong826/prompt-engineering list
npx @ckyong826/prompt-engineering doctor
npx @ckyong826/prompt-engineering show autonomous-project-build-orchestrator
npx @ckyong826/prompt-engineering uninstall --global
```

Note: `npx` pulls from the npm registry. The owner must run
`npm publish --access public` once before the commands above work
for other users. Until then, clone the repo and use Option 2 or 3.

### Option 2: PowerShell (Windows, Linux, macOS)

Works in Windows PowerShell 5.1 and PowerShell 7+.

```powershell
git clone https://github.com/ckyong826/prompt-engineering.git
cd prompt-engineering
.\install.ps1 -Global
```

Project install, two agents only:

```powershell
.\install.ps1 -Project -Agent claude-code,cursor
```

Print one entry as a plain prompt:

```powershell
.\install.ps1 -Show autonomous-project-build-orchestrator
```

No clone, straight from GitHub:

```powershell
& ([scriptblock]::Create((Invoke-RestMethod https://raw.githubusercontent.com/ckyong826/prompt-engineering/main/install.ps1))) -Remote -Global
```

If Windows blocks the script, run it with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Global
```

### Option 3: Bash (Linux, macOS)

```bash
git clone https://github.com/ckyong826/prompt-engineering.git
cd prompt-engineering
chmod +x install.sh
./install.sh --global
```

Project install, two agents only:

```bash
./install.sh --project --agent cursor,opencode
```

Check status:

```bash
./install.sh --doctor --global
```

Print one entry as a plain prompt:

```bash
./install.sh show autonomous-project-build-orchestrator
```

## How to Use

After install, restart your agent. Then use one of these ways.

### Slash command (fastest)

In OpenCode or Claude Code, type `/` and pick the command:

```text
/autonomous-project-build-orchestrator finish the API
```

### Skill (agent loads it)

Tell the agent to use the skill by name:

```text
Use the autonomous-project-build-orchestrator skill.
```

The agent reads `SKILL.md` when the task matches. No copy and paste needed.

### Copy and paste (any AI tool)

Open the prompt file in `prompts/`. Copy the full text.
Paste the text into your AI tool.

### Pipe into a CLI (any terminal tool)

Print the prompt and feed it to another command:

```bash
npx @ckyong826/prompt-engineering show autonomous-project-build-orchestrator | codex exec -
```

```powershell
.\install.ps1 -Show autonomous-project-build-orchestrator | codex exec -
```

```bash
./install.sh show autonomous-project-build-orchestrator | codex exec -
```

Replace `codex exec -` with the CLI you use.

## Agent Coverage

`--global` writes to the home paths. `--project` writes to the project paths.
`.agents/skills` is the shared standard. Most new tools read it.

| Agent | Flag | Project path | Home path |
|-------|------|--------------|-----------|
| Universal | `agents` | `.agents/skills/` | `~/.agents/skills/` |
| Claude Code | `claude-code` | `.claude/skills/` | `~/.claude/skills/` |
| Cursor | `cursor` | `.cursor/skills/` | `~/.cursor/skills/` |
| Codex | `codex` | `.codex/skills/` | `~/.codex/skills/` |
| OpenCode | `opencode` | `.opencode/skills/` | `~/.config/opencode/skills/` |
| Gemini CLI | `gemini-cli` | `.gemini/skills/` | `~/.gemini/skills/` |
| GitHub Copilot | `github-copilot` | `.github/skills/` | `~/.copilot/skills/` |
| Windsurf | `windsurf` | `.windsurf/skills/` | `~/.codeium/windsurf/skills/` |
| Kilo Code | `kilocode` | `.kilocode/skills/` | `~/.kilocode/skills/` |
| Roo Code | `roo` | `.roo/skills/` | `~/.roo/skills/` |
| Kiro CLI | `kiro` | `.kiro/skills/` | `~/.kiro/skills/` |
| Trae | `trae` | `.trae/skills/` | `~/.trae/skills/` |
| Goose | `goose` | `.goose/skills/` | `~/.config/goose/skills/` |
| Droid | `droid` | `.factory/skills/` | `~/.factory/skills/` |
| Antigravity | `antigravity` | `.agent/skills/` | `~/.gemini/antigravity/skills/` |
| Clawdbot | `clawdbot` | `skills/` | `~/.clawdbot/skills/` |
| Neovate | `neovate` | `.neovate/skills/` | `~/.neovate/skills/` |

The installer also copies OpenCode slash commands to
`.opencode/commands/` (project) or `~/.config/opencode/commands/` (home).

## Available Prompts

Click a name to open the full prompt.

| Prompt | What It Does | When to Use It | Run It |
|--------|--------------|----------------|--------|
| [Autonomous Project Build Orchestrator](./prompts/autonomous-project-build-orchestrator.md) | It acts as a senior engineering lead. It inspects your repo, finds missing work, splits the work into small tasks, runs parallel workers, reviews the code, merges safe changes, and runs tests until the project is complete. | Use it when you have a started project, a spec, or a partial repo, and you want an AI team to finish it with quality gates. | `/autonomous-project-build-orchestrator` |

Files:

- Skill source: `./skills/autonomous-project-build-orchestrator/SKILL.md`
- Prompt file: `./prompts/autonomous-project-build-orchestrator.md`
- OpenCode command: `./.opencode/commands/autonomous-project-build-orchestrator.md`

## Add a New Prompt

1. Make a new folder: `skills/<your-skill-name>/`.
2. Use only lowercase letters, numbers, and single hyphens for the name.
3. Add `SKILL.md` in that folder with `name` and `description` at the top.
4. Run `node bin/cli.js export` to build `prompts/<your-skill-name>.md`.
5. Add a command file in `.opencode/commands/<your-skill-name>.md` if you want `/` use.
6. Run `node bin/cli.js list` to check the new skill.
7. Add one row for it in the table above.
