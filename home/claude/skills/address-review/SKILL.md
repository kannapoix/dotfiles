---
name: address-review
description: Work through review comments on the user's own pull request one at a time - verify each claim against the code, let the author decide accept / modify / reject, aim each fix at the commit it belongs to as a fixup (squashed on the spot only while the PR is an unreviewed draft), and draft the reply. Author-side counterpart of review-companion. Use with a PR URL or number, or when the user pastes a review comment and asks whether it holds ("このコメント妥当?", "レビュー対応したい", "address the review"). Never pushes.
argument-hint: "[PR URL or number; omit for the current branch's PR]"
---

The author owns every decision; you own the facts. A review comment, whether from a person or a bot, is a claim to verify, not an order to follow. Each fix is aimed at the commit it belongs to. Once the PR is under review the branch only grows, so a reviewer can read each fix on its own; the author squashes the fixups right before merging, so main still gets the handful of meaningful commits.

Say in one line what you loaded: the PR, its stage, how many unresolved threads, and where the branch stands relative to its base.

## Load

- Resolve the PR: the argument, else `gh pr view --json number,headRefName,baseRefName,url,isDraft,reviews` for the current branch. It is **under review** once it is out of draft or has any review; otherwise it is a **draft**. Confirm the checked-out branch is the PR head and the working tree is clean before any commit.
- Fetch unresolved review threads with `gh api graphql` (`reviewThreads` with `isResolved == false`; keep `path`, `line`, the thread `id`, and each comment's `databaseId`, author, and body). Present them in file order, oldest thread first.
- A comment pasted into the chat ("In `<path>` at line N — review comment from @<login>: ...") joins the same ledger as the next item; match it to a fetched thread when one exists so the reply can land there.
- Read the whole discussion first. A reply the author already gave, or a change already made, counts as settled.

## One comment per turn

```
**[N/M] <path>:<line> @<login>**

> <the comment, trimmed to the claim>

Checked: <what holds and what does not, each with file:line, a command's output, a spec clause, or the primary source>
Options: <a> / <b> / ...
➡️ <recommendation> — fixup of <sha> <subject>  (or: amend! of <sha>, because <what the message gets wrong> / new commit, because <reason> / separate issue)

accept / modify / reject?
```

Then stop. Verify before judging: read the code the comment points at, what calls it, and the upstream docs or source when the claim rests on a tool's behavior. A wrong premise is called out with evidence regardless of who wrote it; a correct and important point is said to be so. Do not soften or inflate. When the reviewer is right about the problem but not the fix, say both.

Pick the target commit by reading `git log --oneline <base>..HEAD` and the history of the touched lines; the commit that introduced the thing under review is the default. Then pick the kind by that commit's message:

- **fixup**: the fix makes the commit do what its message already says.
- **amend!**: the fix makes the message wrong, such as a design change within the same change; it carries the rewritten message.
- **new commit**: the fix needs its own reason in the log, being a separate decision or something that could be reverted on its own.
- **separate issue**: the point is outside the PR's goal; no commit here.

## After the decision

Commit by kind: `git commit --fixup=<sha>`; for amend!, `git commit -m "amend! <subject of sha>" -m "<rewritten message>"`, since `--fixup=amend:` needs an editor and refuses `-m` and `-F`; a new commit gets its own message.

- **accept / modify, under review**: implement, `git add` the files by name, commit, and stop there: no rebase, no squash. `git fetch origin <head>` and check `git merge-base --is-ancestor origin/<head> HEAD`; if the remote moved, show the user before anything else. A base that moved stays as it is; if it conflicts, or the fix needs what landed there, say so and name `git rb` and `git push --force-with-lease` for the author.
- **accept / modify, draft**: note the tip and the branches stacked on it (`git branch --contains HEAD`, minus the current branch), implement, `git add` the files by name, and commit. Then, in this order:
  1. `git fetch` the remote, take the base freshly: `git merge-base HEAD origin/<default>`. Never reuse a base from earlier in the session; another session may have rebased the branch since.
  2. `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>`.
  3. `git diff <old tip> <new tip>` must show the fix and nothing else; `git log --oneline <base>..HEAD` must show the same commits as before. If not, stop and show the user before touching anything else.
  4. Each stacked branch follows with `git rebase --onto <new tip> <old tip> <branch>`, then the same diff check on that branch. Return to the PR branch.
- **reject**: no commit. The reply carries the evidence.
- Either way, draft the reply in the author's voice and in the language the author uses on that PR: the part of the comment that is right comes first, then what was done or why not, in as few sentences as the point allows. Under review, name the fix's short SHA so the reviewer can open just that change. Mark anything you added that the author did not say.

Post a reply only when told to, with `gh api` against the thread's comment id; resolve a thread only when told to. Never push. Name the command the user would run: `git push` under review, `git push --force-with-lease` for a draft.

When every thread is settled and the PR is approved, say the fixups are ready to squash and name the author's commands: `git fetch origin <base>`, `git rebase -i --autosquash origin/<base>`, `git push --force-with-lease`. Branches stacked on the PR follow with `git rebase --onto`.

## Ledger

Keep it in three states: open / settled (decision, landing commit, replied or not) / rejected (reply drafted or posted). Re-list it only when asked, and once at the end:

```
| # | comment | decision | commit | reply |
```

Offer to save the final ledger to the project's memory when the review is done or the session pauses, so a later session can tell what was addressed and what was still owed.
