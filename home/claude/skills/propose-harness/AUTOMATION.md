# Cursor Automation: propose harness

Create this once at https://cursor.com/automations/new then activate it. Cloud Agents cannot save Automations via API.

| Field | Value |
|---|---|
| Name | Propose harness hooks and skills |
| Repository | `kannapoix/dotfiles` |
| Trigger | Scheduled, weekly Monday 09:00 JST (`0 0 * * 1` UTC) |
| Tools | Default Cloud Agent tools. Enable commenting on the PR it opens. Do not grant merge. |
| Active | On |

## Prompt (paste as the automation prompt)

```
Weekly harness review for github.com/kannapoix/dotfiles.

Follow home/claude/skills/propose-harness/SKILL.md exactly.

Look at origin/main (and open session branches) from the last 14 days. Compare against existing hooks in home/modules/claude.nix and skills in home/claude/skills/. Propose at most two high-confidence Claude Code hooks or skills that would remove repeated friction. Do not duplicate improve-harness. Do not reformat flake.nix or ghostty.nix.

If you implement: one commit per change, verify with
nix build '.#homeConfigurations."uk@work-mac".activationPackage'
then inspect result/home-files/ and remove result. Open a draft PR only. Never merge, never git land, never git push origin main. home-manager switch and darwin-rebuild switch are the user's step.

If nothing is worth adding, say so and do not open a PR.
```
