---
name: load-pr
description: Check out a pull request's branch in this session's git worktree so the PR can be reviewed, run, or inspected here exactly as pushed, with HEAD verified against the head commit GitHub reports. Use when the user names a PR (URL or number) and wants it in this session ("PR をこのセッションで見たい", "load PR 123", "check out the PR here"). Session-side counterpart of the git wt-pr alias. Never pushes.
argument-hint: <PR URL or number>
---

Bring the PR's branch into this worktree, confirm what landed, then stop or hand over. This skill only checks out the code; the review itself is review-companion's job.

1. `git status --short` must be empty; otherwise stop and say what is in the way.
2. `gh pr checkout <PR>`.
3. Confirm `git rev-parse HEAD` equals `gh pr view <PR> --json headRefOid -q .headRefOid`. If not, say so and stop; do not reset anything.
4. Report three lines: title and author, `base <- head`, the verified HEAD. If the base is not the default branch, add that branch-wide diffs include the stack and the PR-only diff is `gh pr diff <PR>`. Then check whether the stacked base lags what already landed: `git log --oneline origin/<base>..origin/<default> -- $(gh pr diff <PR> --name-only)` lists the default branch's commits on the PR's files that the base lacks. If it lists any, report them with the files, and whether the default branch dismisses approvals on push (`gh api repos/<owner>/<repo>/rules/branches/<default>`, the `pull_request` rule's `dismiss_stale_reviews_on_push`): when it does not, an approval given now still stands after the conflicts are resolved on retargeting.

The branch belongs to the PR author: do not commit on it unless the user asks, and never push. New commits on the PR: run `gh pr checkout` again, and confirm HEAD as in 3. `git switch -` returns to the branch the session started on.

When `gh pr checkout` fails because the PR was force-pushed, tell what changed in the PR itself apart from what came in with a moved base, before touching the branch:

1. `git fetch origin <base> pull/<PR>/head`. The old head is `HEAD`, the new head is the PR's `headRefOid`, and each one's base is `git merge-base <head> origin/<base>`.
2. `git range-diff <old-base>..<old-head> <new-base>..<new-head>` pairs the commits: `=` is unchanged, `!` shows the change inside a commit.
3. Report "the PR's content is unchanged apart from the base" or list the real changes, with the files.
4. Ask before aligning the local branch, naming the command (`git reset --hard <new-head>`), and run it only on a yes.
