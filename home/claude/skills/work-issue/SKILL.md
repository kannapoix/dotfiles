---
name: work-issue
description: 'Carry out one issue as the execution session, from the issue alone. Use with an issue number or URL ("issue #N に取り組む", "work on issue 123"). Pushes only when the current user message explicitly says to push; never takes a PR out of draft, merges, or applies. Counterpart of write-issue.'
argument-hint: <issue number or URL>
---

The issue is the entire brief, on purpose: the startup prompt carries nothing else, so that a future automatic trigger can send the same thing. Its sections and the parent's spec are the brief: 変更方針 says what to change, 確かめ方 what shows the diff is right, and 完了条件 what the person checks after merge. An issue written before 確かめ方 existed carries a 🤖 block instead, and that block is the instruction. Where the issue is silent on a decision (a behavior, an interface, anything 変更方針 would name) the decision stays the person's. When one option is conservative (leave that code unchanged, skip the operation, hand the step to the person), take it without stopping and carry on: that is a ruling, and it heads the report so the person can overturn it. Only when no option is conservative and any choice would be a guess, stop and present it in the session, numbered, as for a changed premise below: never as an issue comment, and the answer goes back into the issue body. The stops for push, apply, and anything else outside the worktree (5 and 8 below) stay as they are; a ruling only ever declines such a step. Each ruling and each stop measures the issue, so make it visible rather than working around it. A detail below that line, such as a name, the wording of an error, or how a helper is split, you settle yourself and list in the report, so that nothing is decided silently.

Say in one line what you loaded: the issue, its parent, and the branch you will work on.

## Load

- `gh issue view <N> --json title,body,url,comments`, and the parent it links. Read the comments: a later comment overrides the body where they disagree.
- Read the repository's CLAUDE.md and its review guide (REVIEW.md at the root, when present) before writing code.

## Check that the issue still holds

Issues are often cut together and worked in order, so what lands in between can make this one wrong: a sibling's PR settled a decision differently, the parent changed, a file the issue names moved. The premises held when the issue was written; test them against the present before creating the branch.

- Gather what happened after the issue was created: comments on the parent, and its body if edited since; for each sibling not closed by then, its body if edited since, its comments, and the PRs that reference it, with their state and descriptions; and the commits on the base that touch the paths the issue names.
  ```bash
  git fetch origin <base>
  gh api graphql -f query='{ repository(owner: "<owner>", name: "<repo>") { issue(number: <N>) { createdAt parent { lastEditedAt subIssues(first: 50) { nodes { number state closedAt lastEditedAt timelineItems(itemTypes: [CROSS_REFERENCED_EVENT], first: 20) { nodes { ... on CrossReferencedEvent { source { ... on PullRequest { url state mergedAt } } } } } } } } } } }'
  git log --first-parent --since=<createdAt> origin/<base> -- <paths the issue names>
  ```
- Test the issue against that and the code on `origin/<base>`: the facts and links in 背景, each decision in 変更方針, each 確かめ方 condition, and whether a 完了条件 is already met; in an older issue, also each item under 前提の確認, the files and shapes 手順 names, and the 検証 commands.
- A failed item, a claim not true now, or a decision that something landed since contradicts is a changed premise, even where the work could adapt to it; when unsure, count it as one. Shifted line numbers and commits that touch nothing the issue relies on are not. Present the changed premises in the session, numbered: what the issue says and where, what holds now with the link that shows it, and which sections it reaches. Then stop before creating the branch: the plan is the person's to reconsider. Never comment on the issue at this stop, before or after their answer. Whether any of it goes on the issue is the person's call, so write it in the issue's language as text they can paste there unchanged. Once they have updated the issue or answered, on it or in the session, start again from Load. A session answer that changes what the issue says comes first as a proposed change to the issue body, shown in the session and applied with `gh-body-edit` only on their yes, so the issue stays the whole brief.
- Otherwise say in one line what you checked, and create the branch as 前提の確認 says, or, where the issue names none, start the session's branch from `origin/<base>`.

## Decision log

The report is drawn from a log kept while working, not from memory at the end: by then the diff shows what changed, but what was read into the issue, weighed, or doubted on the way is gone or rationalized.

Start it when the branch is created, as `.work-issue/<N>/decisions.md` at the top of the working tree, beside a `.work-issue/.gitignore` that holds `*`, so that nothing under it is committed, no repository config changes, and searches that honor `.gitignore` skip it. When the file already exists, as when the work resumes in a new session, read it and append. Add an entry when the thing happens, before moving on from the code it concerns, under one of these kinds:

- 判断: how you read a decision the issue leaves silent or ambiguous, at the level 変更方針 would name; each ruling, and each decision the person settles in the session, marked 「人が決定」
- 細部: a detail below that line that you settled yourself
- 却下: an approach you weighed and dropped; not a review finding you rejected, which is not recorded
- 低確信: code you are not sure of, an external API whose behavior you could not confirm for the locked version included
- 未証明: behavior no test shows, what the verifier reports under `tests_prove_change` included; where nothing of the kind can be tested, as in prose or configuration, one entry says so for the whole change
- 不可逆: a change that is hard to take back or reaches outside the repository: a migration, a public API, an amount or unit (rounding between units), idempotency, authorization

````markdown
### <n>. <kind>[, <kind>]: <path> <symbol>
- 何を: <the decision or the doubt, in one line>
- なぜ人が見るべきか: <what goes wrong for the user of the change if this is wrong; 「なし」 for 細部 and 却下>
- 選んだ案と代替案: <the choice, and the others that were open>
- 確認方法: <how a reader checks it: a test, a command and its expected result, or the issue line to compare>
````

Name the place by path and symbol, or by heading in prose, not by line: lines move while you work, and the report resolves them at the end.

The 要確認ポイント, the points the person has to check before trusting the change, are the 判断 entries not marked 「人が決定」, and every 低確信, 未証明, and 不可逆 entry; nothing else is flagged as one, and an entry with two kinds is still one. They are not the reviewers' comments on a PR, which address-review and close-out call review points. Five at most: a sixth means the change is too big to review as one, so present a split proposal as in Loop step 1 instead of dropping or merging them to fit. If the person keeps the change whole, the report carries all of them.

## Loop

1. Implement until 確かめ方 holds, in the order 変更方針 and the code call for, or in the order of 手順 where an older issue has one. Before the review pass, `git diff --stat origin/<base>`; measured against [Google's small CLs guide](https://google.github.io/eng-practices/review/developer/small-cls.html), a large change gets a split proposal, presented in the session as for a changed premise, and you wait. So does a log with more than five 要確認ポイント.

   Before using an external API, option, or library, read its version from the lock file (`flake.lock` for nixpkgs, `go.mod`, `Cargo.lock`, and the like) and check how it behaves in the official documentation for that version; where the documentation is thin, the source at the locked version will do. What you could not confirm goes into the verification record. The evidence goes in the PR description or the report, not as a URL in a code comment.
2. Review once, for findings only, then fix what matters. The pass is `/code-review`, without `--fix` and not `ultra`; a 手順 line that names `/code-review --fix` is this pass, run the same way. Rate each finding that holds by what happens to the person who uses the change as it stands, not by the severity the reviewer gave: important when they would get a wrong result, be led into a wrong check, lose data, or hit a step that fails; minor otherwise. Fix the important ones in one pass, with no second review; the verifier in 4 is the next check. Before fixing one that a test can show, write a test that fails on it. Where no test can, as in prose or a runbook, confirm the fix with a syntax check or by running it, stubbing anything outside the worktree. Minor findings stay unfixed and go into the report, so the diff carries only what the issue and the important findings need. Do not record why a finding was rejected. A finding that needs a decision the issue does not cover stays unchanged and goes into the report as a ruling. A reviewer that cannot be launched is named, with the error, in the verification record.
3. Commit as CLAUDE.md sets out, even where 手順 says to keep one commit. A justification that exists for reviewers of this change goes in the commit message and, when a reviewer would ask about another approach, in the description's 選ばなかった案.
4. Verify with the `verifier` subagent, from a clean tree. Give it the issue, the base as `origin/<base>`, and the branch, and nothing of what you did or why, the decision log included: it judges the diff cold, so your account would only steer it. On `accepted-with-reservations`, go on without changing the tree; the reservations reach the person through the verdict in the verification record. On `rejected`, fix what `must_fix` names that the issue covers, commit as in 3, and verify again; after a second rejection, stop and put both verdicts in the report. A `must_fix` that needs a decision the issue does not cover stays unchanged and goes into the report as a ruling. A verifier that cannot be launched is named, with the error, in the verification record.
5. Run `git push` only when the current user message explicitly asks to push. 制約 naming a branch is not that ask, and neither is a request to add a comment, to commit, or to edit the PR description. Otherwise the commit stays local: report its short SHA and the push command (`git push origin HEAD`, or `git push --force-with-lease` when the branch was rewritten), and wait for the person. The draft PR waits with that push.
6. On the turn the person asked to push, once that push has landed, create the draft PR (the hook forces `--draft`) with the description the opening-a-pr skill sets out. If the person already opened the PR, update its description as that skill sets out instead. Do not push in order to reach this step.
7. Present the report below in the session, with the HTML page beside it. Never as an issue or PR comment. A changed premise, a missing decision with no conservative option, and a split proposal are each a numbered stop in the session, as in the check above; none of them is this report.
8. Stop. `gh pr ready`, merge, apply, and release belong to the person. From here `/close-out <PR>` follows the change to its closed issue, ticking the completion conditions and closing the issue on the person's yes. Review comments on the PR are `/address-review`'s job.

Write the PR description, the session report, the decision log, and the HTML page in the language of the issue.

## Report

After implementing, or when waiting for the person to push or apply, present all of the following in the session only:

- first, the rulings: the decisions the issue did not cover that you took on the conservative side, numbered, each as what you chose, why, and what is lost if it was wrong
- the PR URL, or when not pushed the short SHA and the push command
- a summary of the change
- the commands the person runs, with args, env, and expected results
- where to read closely: the lines on a critical path or that carry a judgement, as file:line, so the person spends their reading there
- the verification record below
- the details you settled yourself, each as what you chose, why, and what it costs if wrong
- the minor findings left unfixed, each with where it is and what it costs the person who uses the change

Take the rulings, the details you settled, and the external APIs you could not confirm from the decision log.

Alongside the report, build one HTML page at `.work-issue/<N>/report.html` as [report.md](report.md) beside this file sets out, and end the report with the page's full path. The page adds a reading order for the change; it replaces nothing in the report. When you present the report again after the branch changed, build the page again.

## PR description

The opening-a-pr skill sets out the description: its template, the optional parts, the steps a person runs and their order, and how to change a description the person may be editing. What you verified goes in its 動作確認 as a checklist.

## Verification record

The description's 動作確認 tells reviewers what was verified; the record tells the person who ran you how you checked and what you could not. It is part of the session report above, never a PR or issue comment: it is an exchange between the person and you, and other reviewers do not need it.

````markdown
## 確認したこと
- 検証役の判定: <the verifier's block, verbatim; both blocks when it rejected once>
- 実行した検証: <what ran and what it showed>
- 確かめて問題がなかったもの: <what you looked at and found clean, so that "nothing found" reads differently from "not checked">
- 根拠が見つからなかったもの: <each external API or option whose behavior you could not confirm for the locked version, and what you assumed; omit this line when there were none>
- 起動できなかったレビュー: <which reviewer, and the error; omit this line when every reviewer ran>
- 未実行の検証(認証が要るため。人が実行する):
  ```bash
  <command>   # 期待: <result>
  ```
````

## Measure

The number of edits the PR description took, the number of findings the CI reviewer posted, the number of stops for decisions the issue did not cover, and the number of rulings in the report. All four should fall as the issues get better. Rulings now take most of what used to be a stop, so read those two together; the rule rests on a single trial, so watch them before trusting a trend.
