---
name: work-issue
description: Carry out one issue as the execution session - follow its "🤖 エージェント向け指示" block, run /code-review --fix to convergence, self-review, open a draft PR with the standard description, post the verification record as a PR comment, report on the issue, and stop. A decision the issue does not cover is a comment on the issue, not a guess. Never takes a PR out of draft, merges, or applies; pushes only when the issue names the branch. Use with an issue number or URL ("issue #N に取り組む", "work on issue 123"). Counterpart of write-issue.
argument-hint: <issue number or URL>
---

The issue is the entire brief, on purpose: the startup prompt carries nothing else, so that a future automatic trigger can send the same thing. The human sections (背景, ゴール, 変更方針, 完了条件) are premises; the 🤖 block is the instruction. Where the issue is silent you do not decide: comment on the issue, numbered, and stop, or leave that code unchanged. Each such stop measures the issue, so make it visible rather than working around it.

Say in one line what you loaded: the issue, its parent, and the branch you will work on.

## Load

- `gh issue view <N> --json title,body,url,comments`, and the parent it links. Read the comments: a later comment overrides the body where they disagree.
- Check every item under 前提の確認 first. If one fails, comment what failed and stop.
- Read the repository's CLAUDE.md and its review guide (REVIEW.md at the root, when present) before writing code.

## Loop

1. Implement in the order of 手順. Before the review pass, `git diff --stat origin/<base>`; measured against [Google's small CLs guide](https://google.github.io/eng-practices/review/developer/small-cls.html), a large change gets a split proposal as a comment on the issue, and you wait.
2. `/code-review --fix` until a round produces no findings, at most two rounds. Inside this loop, do not record why a finding was rejected. A finding that needs a decision the issue does not cover stays unchanged and goes into the report.
3. Self-review against the review guide: consistency with the neighbouring code, what the called scripts and modules actually do, failure modes (a failure halfway through, a re-run, a stale checkout).
4. Commit, one commit per change. Until the PR leaves draft you may reshape them; once it is out of draft or reviewed, changes go on as new commits (fixups, as CLAUDE.md sets out), even where 手順 says to keep one commit. The reason a value or an option was chosen goes into the PR description, never into a code comment; a code comment is only for a caveat that applies to the whole file. Push only if 制約 names the branch; otherwise report the branch and the push command, and wait for the person.
5. Once the branch is on the remote, create the draft PR (the hook forces `--draft`) with the description below, then post the verification record as a comment on the PR (`gh pr comment <PR> --body-file`). If the person already opened the PR, update its description with the procedure below instead.
6. Comment on the issue: the PR URL, a summary of the change, the commands the person runs with their expected results, and the decisions the issue did not cover, numbered and unchanged.
7. Stop. `gh pr ready`, merge, apply, and release belong to the person. When they comment results, tick the completion conditions and close the issue. Review comments on the PR are `/address-review`'s job.

Write the PR description, the PR comment, and the issue comment in the language of the issue.

## PR description

````markdown
#<N> に対応。<one line: where this sits under the parent issue>

## 実装方針
- **<decision>**
  - <why, in two or three short sub-bullets>

## 選定の根拠
<only when a choice between candidates needs justifying; a table lists only the candidates that affect the decision>
````

- A term a reader would look up is linked once, at its first occurrence, to the official documentation. Open the page and confirm the term is on it before linking.
- A value not yet measured is written as 「未計測。#N で計測して決める」, with no predicted number or table.
- A decision made with the user during the session goes into the description when it is made, not at the end.
- No 確認したこと section: reviewers do not need it. It goes in the PR comment below.

## Verification comment

The description is for reviewers; what you checked is for the person who ran you. Post it as one comment on the PR right after creating it.

````markdown
## 確認したこと
- 実行した検証: <what ran and what it showed>
- 未実行の検証(認証が要るため。人が実行する):
  ```bash
  <command>   # 期待: <result>
  ```
````

## Updating a PR description

The person edits it on the web while you work, so every change goes through `gh-body-edit`, which replaces one part of the current body and nothing else, aborts unless the anchor occurs exactly once and the body is still what it fetched, keeps the line endings, and checks what landed:

```bash
gh-body-edit pr <N> --replace old.md new.md    # or --append-after anchor.md new.md, or --delete old.md
```

The files hold the exact text and live in the scratchpad. Only the part asked for, no whole-body rewrite from a draft, and nothing you were not asked to change: an instruction to squash, rebase, or push does not include permission to touch the description.

## Measure

The number of edits the PR description took, the number of findings the CI reviewer posted, and the number of stops for decisions the issue did not cover. All three should fall as the issues get better.
