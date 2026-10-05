---
name: work-issue
description: Carry out one issue as the execution session - check that the issue still holds against what landed since it was written, follow its "🤖 エージェント向け指示" block, run the review pass to convergence (Cursor - local /code-review findings only, plus Bugbot and Security Review; Claude Code - /code-review --fix), self-review, open a draft PR with the standard description, present the verification record in the session, report on the issue, and stop. A changed premise or a decision the issue does not cover is a comment on the issue, not a guess. Never takes a PR out of draft, merges, or applies; pushes only when the current user message explicitly says to push. Use with an issue number or URL ("issue #N に取り組む", "work on issue 123"). Counterpart of write-issue.
argument-hint: <issue number or URL>
---

The issue is the entire brief, on purpose: the startup prompt carries nothing else, so that a future automatic trigger can send the same thing. The human sections (背景, ゴール, 変更方針, 完了条件) are premises; the 🤖 block is the instruction. Where the issue is silent you do not decide: comment on the issue, numbered, and stop, or leave that code unchanged. Each such stop measures the issue, so make it visible rather than working around it.

Say in one line what you loaded: the issue, its parent, and the branch you will work on.

## Load

- `gh issue view <N> --json title,body,url,comments`, and the parent it links. Read the comments: a later comment overrides the body where they disagree.
- Read the repository's CLAUDE.md and its review guide (REVIEW.md at the root, when present) before writing code.

## Check that the issue still holds

Issues are often cut together and worked in order, so what lands in between can make this one wrong: a sibling's PR settled a decision differently, the parent changed, a file 手順 names moved. The premises held when the issue was written; test them against the present before creating the branch.

- Gather what happened after the issue was created: comments on the parent, and its body if edited since; for each sibling not closed by then, its body if edited since, its comments, and the PRs that reference it, with their state and descriptions; and the commits on the base that touch the paths the issue names.
  ```bash
  git fetch origin <base>
  gh api graphql -f query='{ repository(owner: "<owner>", name: "<repo>") { issue(number: <N>) { createdAt parent { lastEditedAt subIssues(first: 50) { nodes { number state closedAt lastEditedAt timelineItems(itemTypes: [CROSS_REFERENCED_EVENT], first: 20) { nodes { ... on CrossReferencedEvent { source { ... on PullRequest { url state mergedAt } } } } } } } } } } }'
  git log --first-parent --since=<createdAt> origin/<base> -- <paths the issue names>
  ```
- Test the issue against that and the code on `origin/<base>`: each item under 前提の確認, the facts and links in 背景, each decision in 変更方針, the files and shapes 手順 names, the 検証 commands, and whether a 完了条件 is already met.
- A failed item, a claim not true now, or a decision that something landed since contradicts is a changed premise, even where the work could adapt to it; when unsure, count it as one. Shifted line numbers and commits that touch nothing the issue relies on are not. Comment on the issue, numbered: what the issue says and where, what holds now with the link that shows it, and which sections it reaches. Then stop before creating the branch: the plan is the person's to reconsider. Once they have updated the issue or answered in a comment, start again from Load; an answer given in the session goes on the issue as a comment first, so the issue stays the whole brief.
- Otherwise say in one line what you checked, and create the branch as 前提の確認 says.

## Loop

1. Implement in the order of 手順. Before the review pass, `git diff --stat origin/<base>`; measured against [Google's small CLs guide](https://google.github.io/eng-practices/review/developer/small-cls.html), a large change gets a split proposal as a comment on the issue, and you wait.
2. Review, then fix, until a round leaves no valid finding unaddressed, at most two rounds. A 手順 line that names `/code-review --fix` is this pass. Inside this loop, do not record why a finding was rejected. A finding that needs a decision the issue does not cover stays unchanged and goes into the report. A reviewer that cannot be launched is named, with the error, in the verification record, and the pass continues with the ones that ran.

   When Bugbot and Security Review can be launched as subagents, this is a Cursor session. On one diff, and before anything writes:
   - `claude -p --permission-mode plan --permission-prompts none "/code-review"`. Local review, findings only. No `--fix`, no `ultra`, no `--comment`.
   - Bugbot and Security Review, following the review-bugbot and review-security skills, with `Diff: branch changes` and `Base Branch` set to the issue's base when that base is not the repository default. They return findings and do not edit.
   The three run together. Then apply the findings that hold and that the issue covers. The child session does not edit the tree.

   Otherwise this is a Claude Code session: `/code-review --fix`, and not `ultra`. Bugbot and Security Review are absent here.
3. Self-review against the review guide: consistency with the neighbouring code, what the called scripts and modules actually do, failure modes (a failure halfway through, a re-run, a stale checkout).
4. Commit, one commit per change. Until the PR leaves draft you may reshape them; once it is out of draft or reviewed, changes go on as new commits (fixups, as CLAUDE.md sets out), even where 手順 says to keep one commit. The reason a value or an option was chosen goes into the PR description, never into a code comment; a code comment is only for a caveat that applies to the whole file. Run `git push` only when the current user message explicitly asks to push. 制約 naming a branch is not that ask, and neither is a request to add a comment, to commit, or to edit the PR description. Otherwise the commit stays local: report its short SHA and the push command (`git push origin HEAD`, or `git push --force-with-lease` when the branch was rewritten), and wait for the person. The draft PR waits with that push.
5. On the turn the person asked to push, once that push has landed, create the draft PR (the hook forces `--draft`) with the description below, then present the verification record below to the person in the session. If the person already opened the PR, update its description with the procedure below instead. Do not push in order to reach this step.
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
- No 確認したこと section: reviewers do not need it. It goes in the verification record below.

## Verification record

The description is for reviewers; what you checked is for the person who ran you. Present it in the session right after creating the PR, never as a PR or issue comment: it is an exchange between the person and you, and other reviewers do not need it.

````markdown
## 確認したこと
- 実行した検証: <what ran and what it showed>
- 起動できなかったレビュー: <which reviewer, and the error; omit this line when every reviewer ran>
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
