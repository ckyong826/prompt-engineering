# Prompt Engineering Library

This library stores reusable prompts for software work.
Each prompt solves one clear task in the software flow.
You copy a prompt, paste it into an AI tool, and follow the steps.

## What Is This Library For

You use this library to build software faster and with fewer errors.
It gives you ready prompts for common engineering tasks.
Each prompt tells the AI tool what role to take and what steps to follow.
You do not need to write a long prompt from scratch.

## How to Use a Prompt

1. Open the prompt list below.
2. Click a prompt name to open the full prompt file.
3. Copy the full text from the prompt file.
4. Paste the text into your AI tool.
5. Add your project details where the prompt asks for them.
6. Follow the steps that the AI tool returns.

## Available Prompts

| Prompt | What It Does | When to Use It |
|--------|--------------|----------------|
| [Autonomous Project Build Orchestrator](./autonomous-project-build-orchestractor-prompt.md) | It acts as a senior engineering lead. It inspects your repo, finds missing work, splits the work into small tasks, runs parallel workers, reviews the code, merges safe changes, and runs tests until the project is complete. | Use it when you have a started project, a spec, or a partial repo, and you want an AI team to finish it with quality gates. |

## Add a New Prompt

Put each new prompt in its own `.md` file in this folder.
Then add one row for it in the table above.
Keep the description short, under three lines.
