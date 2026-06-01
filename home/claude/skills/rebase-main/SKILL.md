---
name: rebase-main
description: Rebase the current working branch onto the latest origin main (or master) and push with force-with-lease. Triggered by phrases like "rebase onto main and push", "pull latest main into this branch", "rebase main", or the Japanese equivalents ("main にリベースして push" etc). Also reports CI status of the associated PR.
---

Used when the user's PR is open but main has advanced, and they want to pull main in and re-push.
**The user has pre-authorized this operation.** Run it without asking for confirmation.
Only abort and report if a conflict occurs.

## Steps

1. **Detect the default branch** — Run `git symbolic-ref refs/remotes/origin/HEAD` to determine whether it is `main` or `master`. Fall back to `git remote show origin | grep "HEAD branch"` if needed.

2. **Pre-flight checks** — Run in parallel; abort and report the reason if any fail:
   - `git rev-parse --abbrev-ref HEAD` — get the current branch. Abort if it is main/master itself.
   - `git status --porcelain` — abort if there are uncommitted changes (do NOT auto-stash).

3. **Fetch** — `git fetch origin <default-branch>` to get the latest main.

4. **Check if already up to date** — If `git merge-base --is-ancestor origin/<default-branch> HEAD` succeeds, report "already up to date" and exit. No push needed.

5. **Rebase** — Run `git rebase origin/<default-branch>`.
   - Success → continue.
   - Conflict → `git rebase --abort` to restore the pre-rebase state, report which files conflicted, and exit. **Do not attempt to resolve conflicts** (the user will handle them).

6. **Push** — `git push --force-with-lease` (force-with-lease is required since the rebase rewrote history).

7. **Report PR CI status** — Immediately after the push, run in parallel:
   - `gh pr view --json number,url,state -q '"#" + (.number|tostring) + " " + .state + " " + .url'` — check whether a PR exists.
   - If a PR exists, run `gh pr checks` and summarize the check states (running / pending / failure / success counts).
   - If no PR exists, report "no PR" in a single line.

## Output format

On success:
```
✓ rebased onto origin/main (3 commits replayed)
✓ pushed feature/foo → origin/feature/foo
PR #123 OPEN — CI: 2 passed, 1 running
```

On conflict:
```
✗ rebase aborted due to conflicts in:
  - src/foo.ts
  - src/bar.ts
working tree restored to pre-rebase state. resolve manually and re-run.
```

## Notes

- Never run this on main/master itself (step 2 catches it).
- Always use `--force-with-lease`, never plain `--force` (so other people's pushes are not clobbered).
- If a pre-push hook fails, report the cause and abort. Do NOT bypass with `--no-verify`.
- Run independent git/gh commands in parallel in a single message.
- Do not ask for additional confirmation while executing the steps. Only report on failure.
