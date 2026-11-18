# close-out checks

One row per check. A new check is a new row: an ID with its stage's letter (R review, A approved, M merged), the stages it runs in, what it checks, what settles it, and the next step when it is not ok. Rows stay general; a check one project needs is written as the rule any repository could run.

| ID | Stages | Check | Settled by | Next when not ok |
|---|---|---|---|---|
| R1 | review–done | Every review point is reflected | Each thread is resolved, or answered with the short SHA of a commit on the PR that holds the fix. A point accepted in a reply with no such commit is not reflected. | `/address-review <PR>` |
| R2 | review–approved | CI passes on the head | Every check in `statusCheckRollup` for `headRefOid` succeeded, including the required ones. | A failure the change caused goes to `/address-review` or a fixup; a flaky run, the person reruns it. |
| R3 | review–approved | The PR description matches the code | Each step, decision, and link in the body agrees with the commits and diff now. Links to the PR's own commits, and to lines of a file at one of its commits, point at commits it still has. | A sentence that changed: `gh-body-edit pr <N> --replace`, on a yes. Stale commit or line links: `gh-body-edit pr <N> --relink-commits`, on a yes. |
| R4 | review–approved | The stack is in order | The base PR, when there is one, is still open, or this PR was retargeted after it merged. `git log --oneline origin/<base>..origin/<default> -- <the PR's files>` lists nothing. | The person retargets. The branch follows with `git rb`. |
| A1 | approved | No approval is older than the code | Each approval's commit has the same tree as the head, or the commits after it only fold fixups (`git range-diff` shows no change in content). | The reviewer looks at the commits since their approval. |
| A2 | approved | Fixups are squashed | `git log --format=%s origin/<base>..<head>` shows no `fixup!`, `squash!`, or `amend!`, unless the repository squash-merges. | The person runs `git squash-fixups <base>` and `git push --force-with-lease`; branches stacked on it follow with `git rb`. |
| A3 | approved | Steps before merge are done | Each step the PR description puts before merge, such as an apply to a dev environment, has a result for the current head: a CI run or comment, a log, or the person's report in the session. | person |
| M1 | merged–done | It reached the branch that closes issues | Merged into the default branch. A merge into another branch, as in a stack, closes no issue; its issues stay open until the change reaches the default branch. | Wait for the stack to land; do not propose closing yet. |
| M2 | merged–done | Steps after merge are done | Each step the PR description puts after merge, and each deploy that merging starts, has a run that took the merge commit or a later one. | person, with the commands in order |
| M3 | merged–done | 完了条件 that can be ticked | Each unticked line has a link that shows it: the merge, an apply's run or comment, a check's output. A line with none stays open, with who checks it and how. | Propose ticking it, one line per item. |
| M4 | merged–done | Issues it closes are closed | Each closing reference is closed, with this PR as the closer in its timeline. | Propose closing it, once M1 and M3 are ok for it. |
| M5 | merged–done | The parent can move on | The parent's status comment names what is left. When every sub-issue is closed and every 完了条件 line ticked, the parent can close. | Propose the status comment update, and closing the parent when nothing is left. |
| M6 | merged | Stacked PRs follow | Each PR based on the merged branch is retargeted to the default branch and carries none of the merged PR's old commits. | The person retargets (GitHub does it when it deletes the merged branch); each branch then runs `git rb`. |
| M7 | merged–done | Local clean-up | The merged branch's worktree and local branch are gone, or kept on purpose. | Name the commands; never run them. |
