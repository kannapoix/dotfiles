---
name: load-pr
description: Check out a pull request's branch in this session's git worktree so the PR can be reviewed, run, or inspected here exactly as pushed, with HEAD verified against the head commit GitHub reports. Use when the user names a PR (URL or number) and wants it in this session ("PR をこのセッションで見たい", "load PR 123", "check out the PR here"). Session-side counterpart of the git wt-pr alias. Never pushes.
argument-hint: <PR URL or number>
---

Bring the PR's branch into this worktree, confirm what landed, then stop or hand over. This skill only checks out the code; the review itself is review-companion's job.

1. `git status --short` must be empty; otherwise stop and say what is in the way.
2. `gh pr checkout <PR>`.
3. Confirm `git rev-parse HEAD` equals `gh pr view <PR> --json headRefOid -q .headRefOid`. If not, say so and stop; do not reset anything.
4. Report three lines: title and author, `base <- head`, the verified HEAD. If the base is not the default branch, add that branch-wide diffs include the stack and the PR-only diff is `gh pr diff <PR>`.

The branch belongs to the PR author: do not commit on it unless the user asks, and never push. New commits on the PR: run `gh pr checkout` again; it fast-forwards and fails if the PR was force-pushed, which the user decides about. `git switch -` returns to the branch the session started on.
