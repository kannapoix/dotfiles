---
name: improve-harness
description: Turn friction noticed in this session into a handoff brief for the dotfiles session, where it becomes a skill, a setting, an alias, or a memory. Use when the user notices something worth fixing in how Claude works ("これ skill にしたい", "毎回同じ指示をしてる", "improve the harness") or wants a retrospective on the session's tooling.
argument-hint: "[one improvement to capture; omit to review the whole session]"
disable-model-invocation: true
---

You are collecting improvements to the **harness**: the skills, settings, hooks, git aliases, and memories that shape how Claude works in every project. The harness lives in the dotfiles repo, so improvements are written up as a **brief** that the user pastes into a fresh dotfiles session. That session cannot see this conversation; the brief must stand on its own.

## Mode

- **With arguments**: capture that one improvement only.
- **Without arguments**: review this session for candidates. Look for:
  - the same instruction given two or more times
  - a permission prompt that appears on every run
  - a procedure the user explained by hand instead of pointing at a file
  - information that took a long time to find
  - something Claude did that it should not have

  Rank candidates by severity and walk them one at a time: what you saw, the evidence, and whether to include it. Wait for the answer before moving on.

## Portable or project-local

For each candidate, settle with the user whether it belongs in the harness (every project) or in this project only. Project-local items are applied here and now (CLAUDE.md, the project's memory, or `.claude/settings.json`; ask before editing a git-tracked file) and do not go in the brief.

## The brief

One fenced code block, starting with the line `# Harness improvement brief`, the project name, and the date. For each item:

- **What happened**: quote the actual commands, tool calls, or prompts, and how many times it recurred.
- **Desired behavior**: what should happen next time.
- **Concrete example**: for a skill, the invocation and expected output; for an alias, the command as typed; for a setting, the exact rule.
- **Tentative type**: skill, claude.nix setting (permission or hook), git.nix alias, memory, or CLAUDE.md. A guess the dotfiles session may overrule.
- **References**: paths, PR or issue URLs, commit hashes. Point at existing artifacts instead of restating them.

Redact secrets, tokens, and personal data.
