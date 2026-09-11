---
name: propose-harness
description: Review recent harness usage and propose Claude Code hooks or skills. Use for the weekly Cursor Automation, or when the user asks to suggest hooks/skills from recent git history ("hook や skill を提案", "propose harness").
---

You are reviewing the **harness** in this repo: Claude Code (and Cursor-compatible) hooks, skills, settings, git aliases, and memories that shape how the agent works in every project.

This skill is the body of a scheduled Cursor Automation. Follow it without asking the user to settle cadence, destination, or scope.

## Defaults (already decided)

- **Cadence**: weekly (the dashboard cron). If invoked by hand, review about the last 14 days.
- **Scope**: hooks and skills only. Do not drive-by reformat `flake.nix` / `ghostty.nix` or other unrelated files.
- **Output**: implement at most **two** high-confidence proposals. Otherwise write a short "nothing to add" summary and stop.
- **Landing**: never merge, never `git land`, never `git push origin main`. Applying `home-manager switch` / `darwin-rebuild switch` is the user's step.

## Read first (do not duplicate)

- `home/modules/claude.nix` — existing hooks and permissions
- `home/claude/skills/*/SKILL.md` — existing skills, especially `improve-harness` (in-session capture; this skill is the periodic counterpart)
- `home/claude/CLAUDE.md` and repo `CLAUDE.md`
- `home/modules/git.nix` aliases that already encode a workflow

## What to look at

1. `git log` on `origin/main` since the last review window (default 14 days), plus open session branches if present.
2. Recurring friction that a hook or skill would remove: repeated instructions, always-ask permissions that should be allow/ask with a reason, a procedure explained in chat instead of a file, a check that should run automatically.
3. Gaps relative to `CLAUDE.md` (for example a rule that is written but not enforced).

Skip anything that is already a hook, skill, alias, or memory. Skip one-off noise. Skip proposals that need project names, work hostnames, or key filenames in this public repo.

## If you implement

- A hook lives in `home/modules/claude.nix`. A skill is `home/claude/skills/<name>/SKILL.md`. The flake only sees tracked files, so `git add` a new skill directory before verifying.
- One commit per change. Verify with `nix build '.#homeConfigurations."uk@work-mac".activationPackage'`, inspect `result/home-files/`, then remove `result`.
- **Cloud Agent / Cursor Automation**: commit, push the session branch, open a **draft** PR (`gh pr create --draft` or the PR tool), then stop. Do not merge.
- **Local Claude Code in a `~/dotfiles` worktree**: commit on the `claude/*` branch, do not push, do not open a PR, print `git land` and `git push origin main` for the user.

## If you do not implement

End with a short recap: window reviewed, candidates considered, why each was dropped. No empty PR, no empty commit.

## Registering the Cursor Automation

This repo cannot create the dashboard object. After this skill lands, create it once at https://cursor.com/automations/new using `AUTOMATION.md` in this directory.
