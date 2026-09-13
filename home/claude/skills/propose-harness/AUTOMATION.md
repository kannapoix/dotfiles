# Cursor Automation: propose harness

Create this once at https://cursor.com/automations/new then activate it. Cloud Agents cannot save Automations via API.

| Field | Value |
|---|---|
| Name | Propose harness from recent sessions |
| Repository | `kannapoix/dotfiles` (needed so the run can read existing skills/hooks) |
| Machine | Self-hosted worker on the personal Mac, not a public cloud VM. Local Cursor Agent transcripts live under `~/.cursor/projects/*/agent-transcripts/` on that machine. |
| Trigger | Scheduled, weekly Monday 09:00 JST (`0 0 * * 1` UTC) |
| Tools | Default Cloud Agent tools. No merge. No need to comment on a PR. |
| Active | On |

A public-cloud run can list Cloud Agents. It cannot read local Cursor chats. Target the Mac worker so both corpora are in play.

## Prompt (paste as the automation prompt)

```
Weekly harness review for Kan.

Follow home/claude/skills/propose-harness/SKILL.md exactly.

Look at sessions with the user from the last 7 days:
- Cursor local Agent transcripts under ~/.cursor/projects/*/agent-transcripts/
- Cloud Agent runs (list-cloud-agents + transcripts)

Compare against existing hooks in home/modules/claude.nix and skills in home/claude/skills/. Propose skills or Cursor Automations that would make those sessions smoother. Do not implement, do not commit, do not open a PR. Do not duplicate improve-harness. Do not reformat flake.nix or ghostty.nix.

If ~/.cursor/projects is missing, say local Cursor sessions were skipped. If nothing is worth adding, say so.
```
