# Cursor Automation: propose harness

Create this once at https://cursor.com/automations/new then activate it. Cloud Agents cannot save Automations via API.

| Field | Value |
|---|---|
| Name | Propose harness from recent sessions |
| Repository | `kannapoix/dotfiles` (needed so the run can read existing skills/hooks) |
| Trigger | Scheduled, weekly Monday 09:00 JST (`0 0 * * 1` UTC) |
| Tools | Default Cloud Agent tools. No merge. No need to comment on a PR. |
| Active | On |

## Prompt (paste as the automation prompt)

```
Weekly harness review for Kan.

Follow home/claude/skills/propose-harness/SKILL.md exactly.

Look at Cloud Agent sessions with the user from the last 7 days (list-cloud-agents + transcripts). Compare against existing hooks in home/modules/claude.nix and skills in home/claude/skills/. Propose skills or Cursor Automations that would make those sessions smoother. Do not implement, do not commit, do not open a PR. Do not duplicate improve-harness. Do not reformat flake.nix or ghostty.nix.

If nothing is worth adding, say so.
```
