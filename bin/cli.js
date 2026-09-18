#!/usr/bin/env node
"use strict";
// prompt-engineering installer CLI. No dependencies, Node >= 16.
// One canonical source (skills/<name>/SKILL.md) installed into every agent.
const fs = require("fs");
const os = require("os");
const path = require("path");

const PKG_ROOT = path.resolve(__dirname, "..");
const SKILLS_SRC = path.join(PKG_ROOT, "skills");
const COMMANDS_SRC = path.join(PKG_ROOT, ".opencode", "commands");

// Agent target map. project = relative to project dir, global = ~/... .
// Sources: vendor docs + community tables (Claude Code, Cursor, Codex,
// OpenCode, Gemini CLI, Copilot docs, 2026).
const AGENTS = {
  agents:           { label: "Universal (.agents)", project: ".agents/skills",            global: "~/.agents/skills" },
  "claude-code":    { label: "Claude Code",         project: ".claude/skills",            global: "~/.claude/skills" },
  cursor:           { label: "Cursor",              project: ".cursor/skills",            global: "~/.cursor/skills" },
  codex:            { label: "Codex",               project: ".codex/skills",             global: "~/.codex/skills" },
  opencode:         { label: "OpenCode",            project: ".opencode/skills",          global: "~/.config/opencode/skills" },
  "gemini-cli":     { label: "Gemini CLI",          project: ".gemini/skills",            global: "~/.gemini/skills" },
  "github-copilot": { label: "GitHub Copilot",      project: ".github/skills",            global: "~/.copilot/skills" },
  windsurf:         { label: "Windsurf",            project: ".windsurf/skills",          global: "~/.codeium/windsurf/skills" },
  kilocode:         { label: "Kilo Code",           project: ".kilocode/skills",          global: "~/.kilocode/skills" },
  roo:              { label: "Roo Code",            project: ".roo/skills",               global: "~/.roo/skills" },
  kiro:             { label: "Kiro CLI",            project: ".kiro/skills",              global: "~/.kiro/skills" },
  trae:             { label: "Trae",                project: ".trae/skills",              global: "~/.trae/skills" },
  goose:            { label: "Goose",               project: ".goose/skills",             global: "~/.config/goose/skills" },
  droid:            { label: "Droid",               project: ".factory/skills",           global: "~/.factory/skills" },
  antigravity:      { label: "Antigravity",         project: ".agent/skills",             global: "~/.gemini/antigravity/skills" },
  clawdbot:         { label: "Clawdbot",            project: "skills",                    global: "~/.clawdbot/skills" },
  neovate:          { label: "Neovate",             project: ".neovate/skills",           global: "~/.neovate/skills" },
};

// OpenCode slash commands ship alongside skills.
const COMMAND_TARGETS = {
  project: ".opencode/commands",
  global: "~/.config/opencode/commands",
};

function expandHome(p) {
  if (p === "~") return os.homedir();
  if (p.startsWith("~/") || p.startsWith("~\\")) return path.join(os.homedir(), p.slice(2));
  return p;
}

function readFrontmatter(file) {
  const out = {};
  try {
    const text = fs.readFileSync(file, "utf8").replace(/^\uFEFF/, "");
    const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (!m) return out;
    for (const line of m[1].split(/\r?\n/)) {
      const i = line.indexOf(":");
      if (i > 0) out[line.slice(0, i).trim()] = line.slice(i + 1).trim();
    }
  } catch (e) { /* missing file -> {} */ }
  return out;
}

function listSkills() {
  if (!fs.existsSync(SKILLS_SRC)) return [];
  return fs.readdirSync(SKILLS_SRC, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name)
    .filter((n) => fs.existsSync(path.join(SKILLS_SRC, n, "SKILL.md")))
    .sort();
}

function listCommands() {
  if (!fs.existsSync(COMMANDS_SRC)) return [];
  return fs.readdirSync(COMMANDS_SRC)
    .filter((f) => f.endsWith(".md"))
    .sort();
}

function copyDir(src, dest) {
  if (typeof fs.cpSync === "function") {
    fs.cpSync(src, dest, { recursive: true, force: true });
    return;
  }
  // Fallback for old Node: manual recursive copy.
  fs.mkdirSync(dest, { recursive: true });
  for (const e of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, e.name), d = path.join(dest, e.name);
    if (e.isDirectory()) copyDir(s, d);
    else fs.copyFileSync(s, d);
  }
}

function removeDir(dir) {
  if (typeof fs.rmSync === "function") fs.rmSync(dir, { recursive: true, force: true });
  else if (fs.existsSync(dir)) fs.rmdirSync(dir, { recursive: true });
}

function parseArgs(argv) {
  const o = { cmd: "install", global: false, project: false, dir: null,
    agents: null, skills: null, dryRun: false, json: false, help: false, version: false };
  const rest = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "install" || a === "list" || a === "doctor" || a === "uninstall") o.cmd = a;
    else if (a === "--global" || a === "-g") o.global = true;
    else if (a === "--project" || a === "-p") o.project = true;
    else if (a === "--dir") o.dir = argv[++i];
    else if (a === "--agent" || a === "-a") (o.agents = o.agents || []).push(...argv[++i].split(",").map((s) => s.trim().toLowerCase()).filter(Boolean));
    else if (a === "--skill" || a === "-s") (o.skills = o.skills || []).push(...argv[++i].split(",").map((s) => s.trim()).filter(Boolean));
    else if (a === "--dry-run") o.dryRun = true;
    else if (a === "--json") o.json = true;
    else if (a === "--help" || a === "-h") o.help = true;
    else if (a === "--version" || a === "-V") o.version = true;
    else rest.push(a);
  }
  if (rest.length && !o.help) { console.error("Unknown args: " + rest.join(" ")); o.help = true; }
  return o;
}

function pkgVersion() {
  try { return JSON.parse(fs.readFileSync(path.join(PKG_ROOT, "package.json"), "utf8")).version; }
  catch (e) { return "0.0.0"; }
}

function help() {
  console.log([
    "prompt-engineering " + pkgVersion() + " - install prompt skills into coding agents",
    "",
    "Usage:",
    "  prompt-eng <command> [options]",
    "",
    "Commands:",
    "  install     Copy skills into agent directories (default)",
    "  list        Show bundled skills and supported agents",
    "  doctor      Show which skills are installed where",
    "  uninstall   Remove installed skills",
    "",
    "Options:",
    "  --global, -g      Install to user home (all projects). Default.",
    "  --project, -p     Install into current project directory.",
    "  --dir <path>      Install into a custom directory as project root.",
    "  --agent, -a a,b   Target agents (default: all). See list.",
    "  --skill, -s n,m   Install only these skills (default: all).",
    "  --dry-run         Print what would change, change nothing.",
    "  --json            Machine-readable output for list/doctor.",
    "",
    "Examples:",
    "  npx @ckyong826/prompt-engineering install --global",
    "  npx @ckyong826/prompt-engineering install --project --agent claude-code,cursor",
    "  npx @ckyong826/prompt-engineering install --dir ./my-app --agent opencode",
    "  npx @ckyong826/prompt-engineering doctor",
  ].join("\n"));
}

function targetsFor(opts) {
  const base = opts.dir ? path.resolve(opts.dir)
    : opts.project ? process.cwd() : null; // null = global
  const keys = opts.agents || Object.keys(AGENTS);
  for (const k of keys) if (!AGENTS[k]) { console.error("Unknown agent: " + k + ". Run list to see supported agents."); process.exit(1); }
  return { base, keys, isGlobal: !opts.project && !opts.dir };
}

function cmdList(opts) {
  const skills = listSkills().map((n) => {
    const fm = readFrontmatter(path.join(SKILLS_SRC, n, "SKILL.md"));
    return { name: fm.name || n, dir: n, description: fm.description || "" };
  });
  const agents = Object.entries(AGENTS).map(([key, a]) => ({ key, label: a.label, project: a.project, global: a.global }));
  if (opts.json) { console.log(JSON.stringify({ skills, agents }, null, 2)); return; }
  console.log("Skills (" + skills.length + "):");
  for (const s of skills) console.log("  - " + s.name + (s.description ? " : " + s.description : ""));
  console.log("Commands (" + listCommands().length + "):");
  for (const c of listCommands()) console.log("  - /" + c.replace(/\.md$/, ""));
  console.log("Agents (" + agents.length + "):");
  for (const a of agents) console.log("  - " + a.key + " (" + a.label + ") project=" + a.project + " global=" + a.global);
}

function planCopies(opts) {
  const { base, keys, isGlobal } = targetsFor(opts);
  const wanted = opts.skills || listSkills();
  const known = new Set(listSkills());
  for (const s of wanted) if (!known.has(s)) { console.error("Unknown skill: " + s + ". Run list to see bundled skills."); process.exit(1); }
  const copies = [];
  for (const skill of wanted) {
    const src = path.join(SKILLS_SRC, skill);
    for (const k of keys) {
      const root = isGlobal ? expandHome(AGENTS[k].global) : path.join(base, AGENTS[k].project);
      copies.push({ kind: "skill", agent: k, skill, src, dest: path.join(root, skill) });
    }
    if (!opts.agents || opts.agents.includes("opencode")) {
      const croot = isGlobal ? expandHome(COMMAND_TARGETS.global) : path.join(base, COMMAND_TARGETS.project);
      for (const c of listCommands()) {
        copies.push({ kind: "command", agent: "opencode", skill, src: path.join(COMMANDS_SRC, c), dest: path.join(croot, c), file: true });
      }
    }
  }
  return { copies, isGlobal, base };
}

function cmdInstall(opts) {
  const skills = listSkills();
  if (!skills.length) { console.error("No skills found in " + SKILLS_SRC); process.exit(1); }
  const { copies, isGlobal, base } = planCopies(opts);
  const where = isGlobal ? "global (" + os.homedir() + ")" : "project (" + base + ")";
  let done = 0;
  for (const c of copies) {
    if (opts.dryRun) { console.log("[dry-run] " + c.kind + " [" + c.agent + "] " + c.src + " -> " + c.dest); continue; }
    if (c.file) fs.mkdirSync(path.dirname(c.dest), { recursive: true });
    else fs.mkdirSync(path.dirname(c.dest), { recursive: true });
    if (c.file) fs.copyFileSync(c.src, c.dest);
    else copyDir(c.src, c.dest);
    console.log("[OK] " + c.kind + " [" + c.agent + "] -> " + c.dest);
    done++;
  }
  if (!opts.dryRun) console.log(done + " item(s) installed to " + where + ". Restart your agent to pick them up.");
}

function cmdDoctor(opts) {
  const { base, keys, isGlobal } = targetsFor({ ...opts, agents: opts.agents });
  const skills = opts.skills || listSkills();
  const rows = [];
  for (const k of keys) {
    const root = isGlobal ? expandHome(AGENTS[k].global) : path.join(base, AGENTS[k].project);
    for (const s of skills) {
      const hit = fs.existsSync(path.join(root, s, "SKILL.md"));
      rows.push({ agent: k, skill: s, path: path.join(root, s), installed: hit });
    }
  }
  if (opts.json) { console.log(JSON.stringify(rows, null, 2)); return; }
  const scope = isGlobal ? "global" : "project " + base;
  console.log("Skill status (" + scope + "):");
  for (const r of rows) console.log("  [" + (r.installed ? "OK" : "--") + "] " + r.agent + " / " + r.skill + " " + r.path);
}

function cmdUninstall(opts) {
  const { copies, isGlobal, base } = planCopies(opts);
  const where = isGlobal ? "global (" + os.homedir() + ")" : "project (" + base + ")";
  let done = 0;
  for (const c of copies) {
    if (!fs.existsSync(c.dest)) { console.log("[--] missing " + c.dest); continue; }
    if (opts.dryRun) { console.log("[dry-run] remove " + c.dest); continue; }
    if (c.file) fs.unlinkSync(c.dest);
    else removeDir(c.dest);
    console.log("[OK] removed " + c.dest);
    done++;
  }
  if (!opts.dryRun) console.log(done + " item(s) removed from " + where + ".");
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  if (opts.version) { console.log(pkgVersion()); return; }
  if (opts.help) { help(); return; }
  if (!opts.project && !opts.dir) opts.global = true; // default scope
  if (opts.cmd === "list") cmdList(opts);
  else if (opts.cmd === "doctor") cmdDoctor(opts);
  else if (opts.cmd === "uninstall") cmdUninstall(opts);
  else cmdInstall(opts);
}
main();
