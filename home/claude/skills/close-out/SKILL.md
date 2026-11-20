---
name: close-out
description: 'Take a pull request or issue from review to a closed issue: where it stands, what is left, who does what next, and where it gets released, as one table of checks with evidence. Use after work-issue has opened a PR, through review fixes, merge, apply or release, and closing the issue ("/close-out 123", "マージしていい?", "close できる issue ある?", "完了条件どれ埋まった?", "反映漏れない?", "次何する?"). Reads only; ticks a completion condition or closes an issue one item at a time on the user''s yes. Never readies, merges, applies, or releases.'
argument-hint: "[PR or issue number or URL; omit for the current branch's PR]"
---

The person readies, merges, applies, and releases. You find out where the change stands, with evidence, and say what is next and who does it. The checks are rows in [checks.md](checks.md); this file says how to run them and how to report.

## Locate

The target is the argument, else the current branch's PR. From a PR, read it with its reviews, review threads, and closing issues in one query:

```bash
gh api graphql -F owner=<owner> -F repo=<repo> -F pr=<N> -f query='query($owner: String!, $repo: String!, $pr: Int!) { repository(owner: $owner, name: $repo) { pullRequest(number: $pr) { state isDraft baseRefName headRefName headRefOid mergedAt mergeCommit { oid } reviewDecision latestReviews(first: 20) { nodes { state author { login } commit { oid } } } reviewThreads(first: 100) { nodes { isResolved path comments(first: 1) { nodes { url } } } } closingIssuesReferences(first: 20) { nodes { number state parent { number } } } } } }'
```

Add the PR's body, commits, and checks on the head (`gh pr view <N> --json body,commits,statusCheckRollup`), the PRs stacked on it (`gh pr list --base <head branch>`), and, when its base is not the default branch, the PR whose head that base is. For each issue the PR closes or its body names as its issue, read its body with the 完了条件 checklist, its parent, and the parent's sub-issues with their 完了条件 (`issue(number:) { state body parent { number } subIssues(first: 50) { nodes { number state } } closedByPullRequestsReferences(first: 10, includeClosedPrs: true) { nodes { number mergedAt baseRefName } } }`). From an issue, start at those PRs and do the same.

Then name the stage, the first that fits: **review** (open, not approved), **approved** (open, approved), **merged** (merged, with steps after merge or issues still open), **done** (merged, those steps have results, and its issues are closed). Say it in one line, with the fact that decides it.

## Check

Run every row of checks.md whose stage range includes this stage; a row for an earlier stage still runs, since a review point forgotten before merge is still forgotten after it. Each row gives one verdict:

- **ok**, with a link to what shows it: a commit, a CI run, a comment, a timeline event.
- **blocked**: something has to happen first; say what and who does it.
- **person**: only the person can check it, in a live environment or a dashboard; say where to look and what to expect.
- **unknown**: the lookup failed, or came back empty where it should not have.

## Report

In the language of the issue:

1. The target, its stage, and the fact that decides the stage.
2. A table: check (ID and name) | verdict | evidence | next.
3. Where it goes out: what merging runs (workflows on pushes to the default branch, the steps the PR description puts after merge) and which environment each reaches.
4. Next: the one step that unblocks the most, and who takes it. The person's steps are exact commands in order, one fenced block each.
5. Proposals, numbered: each one change you can make on a yes, with what it changes and the evidence. These are ticking one 完了条件 line or closing one issue. Steps that are the person's never appear here.

Then stop.

## On a yes

Do only the numbered items the person said yes to, one at a time; a yes to 2 is not a yes to 3. Tick a line with `gh-body-edit issue <N> --replace old.md new.md`, where old.md holds the line with `[ ]` and new.md the same line with `[x]`. Close an issue with `gh issue close <N> --comment "<one line: the evidence, linked>"`. Report each result, then run that row again.

Work the checks turn up goes to its own skill: a review point not yet reflected to `/address-review <PR>`, a decision that changed to write-issue's Update, and a fix a failed 完了条件 needs to write-issue as a new sub-issue.

## Do not

- Do not run `gh pr ready`, merge, apply, deploy, release, retarget a PR, or push.
- Do not tick, close, comment, or edit a body without a yes for that item.
- Do not tick a 完了条件 line without a link to what shows it.
- Do not treat a failed lookup or empty output as none.
- Do not call a change released because its PR merged.
- Do not delete a branch or a worktree; name the command.

## Measure

Count what the checks find after merge that a check before merge should have caught, such as a forgotten review point or a stale PR description. It should fall; when it does not, the row that missed it needs sharpening.
