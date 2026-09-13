---
name: propose-harness
description: Review the last week's sessions with the user and propose skills or Cursor Automations that would make those sessions smoother. Use for the weekly Cursor Automation, or when the user asks to suggest skills/automations from recent chats ("hook や skill を提案", "propose harness", "セッションを振り返って").
---

You are looking back at **sessions with this user** and proposing harness changes. Do not implement them.

This skill is the body of a scheduled Cursor Automation. Follow it without asking the user to settle cadence or scope.

## Defaults (already decided)

- **Window**: last 7 days when the dashboard cron is weekly. If invoked by hand, use the last 7 days unless the user names another window.
- **Output**: proposals only. No code, no commits, no PRs, no `git land`.
- **Shape**: "こんな skill を作るとよい" / "こんな Cursor Automation を作るとよい", each with evidence from the sessions. Cap at a handful of high-confidence items. If nothing is worth adding, say so.

`improve-harness` is the in-session capture skill. This one is the periodic retrospective across chats.

## Read existing harness first (do not duplicate)

- `home/modules/claude.nix` — hooks and permissions
- `home/claude/skills/*/SKILL.md`
- `home/claude/CLAUDE.md` and repo `CLAUDE.md`
- `home/modules/git.nix` aliases

Skip anything already covered. Skip one-off noise. Skip proposals that need project names, work hostnames, or key filenames in this public repo.

## What to look at: sessions, not git history

Git log is optional context. The source of truth is conversations with the user. Cover **both** corpora below. If one is missing, say which and why.

### Cursor local Agent sessions (the Mac)

These live on the machine, not in Cloud Agent APIs. A public-cloud VM will not have them. This Automation is supposed to run on the personal Mac self-hosted worker so `~/.cursor` is readable.

1. If `~/.cursor/projects` exists, list `*/agent-transcripts/` (JSONL, one conversation per file). Keep files whose mtime (or last write) falls in the window.
2. Summarize each via a subagent. Do not dump a whole transcript into the proposal. Redact secrets, tokens, and personal data.
3. Recover: what the user asked, where the agent stalled or was corrected, procedures explained by hand, repeated instructions, missing tools, work that should have been a scheduled or event-triggered Automation.

If `~/.cursor/projects` is absent, you are not on the Mac. Say that local Cursor sessions were skipped, and stop pretending you reviewed them. Composer-only chats that never wrote `agent-transcripts` are also out of reach (they sit in the local DB); mention that gap if it matters.

### Cloud Agent sessions

1. List runs visible to this principal with `cursor-cloud` `list-cloud-agents`: `createdAfter` at the window start (ISO-8601 UTC), `includeArchived` true. Page with `offset` until `hasMore` is false. Include desktop, web, slack, automations, local, and other sources; do not filter them out. `source: desktop` means a **Cloud Agent started from the app**, not a local Agent chat.
2. Fetch transcripts with `batch-fetch-details` (`includeTranscripts` true, `includeEvents` true). Transcripts are large — summarize each via a subagent; do not read `transcript.json` yourself.
3. Same friction questions as for local sessions.

Local Claude Code sessions that never became a Cloud Agent run and never wrote Cursor `agent-transcripts` stay out of scope.

## Proposal format

For each item:

- **Kind**: skill or Cursor Automation (and trigger, if Automation)
- **What happened**: quote or paraphrase the session(s), with enough identity to find them (local transcript filename, or Cloud Agent name/URL) and about when
- **Proposal**: the skill or Automation in enough detail that a later session could implement it
- **Why it would smooth those sessions**: the repeated friction it removes

Do not open a PR. Do not edit harness files as part of the review run. Registering a new Cursor Automation in the dashboard is the user's step; this skill only recommends it.
