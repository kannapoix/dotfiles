---
name: commit-and-push
description: Use when the user wants to bundle recent edits into a single commit and push it to the remote. Triggered by phrases like "commit and push", "squash into one and push", "ship it", "push this", or their Japanese equivalents ("commit して push", "まとめて push" etc).
---

Procedure for bundling the user's recent edits into a single commit and pushing it to the remote.

## Steps

1. **Inspect current state** — run in parallel:
   - `git status` (working tree state, including untracked files)
   - `git diff` (staged + unstaged)
   - `git log <merge-base>..HEAD` (commits stacked on this branch)
   - `git rev-parse --abbrev-ref HEAD` (current branch name)
   - `git config branch.<current>.remote` or `git remote` (push target)

2. **Prepare to bundle into a single commit**:
   - If there are multiple existing commits on the branch, confirm with the user ("I'll squash N commits into one") and then run `git reset --soft $(git merge-base HEAD <upstream-branch>)` to set the stage.
   - If there are no existing commits and only uncommitted changes, do nothing here.

3. **Stage** — add only the relevant files **by name** with `git add`. Do not use `-A` or `.`. Exclude `.env` or credential files; warn if they might be included.

4. **Draft the commit message** — read the last 3-5 `git log` entries to match the repository's commit message style. State the "why" in 1-2 lines. Pass via HEREDOC to preserve formatting.

5. **Create the commit.**

6. **Always confirm with the user before pushing** — ask "Ready to push. OK?". Pushing is visible to others, so do not auto-approve.

7. **Push once approved**:
   - History was rewritten (i.e. an existing commit was squashed) → `git push --force-with-lease`
   - Only added new commits → plain `git push`
   - Upstream not set → `git push -u origin <branch>`

## Notes

- Never force-push on the main / master branch (warn and abort).
- If squashing commits that have already been pushed to the remote, warn about the impact on collaborators.
- If a pre-commit hook fails, fix the cause and create a **new** commit (do NOT use `--amend`).
- Run independent git commands in parallel within a single message.
