---
name: address-review
description: Work through review comments on the user's own pull request one at a time - verify each claim against the code, let the author decide accept / modify / reject, fold the fix into the right existing commit with fixup + autosquash, and draft the reply. Author-side counterpart of review-companion. Use with a PR URL or number, or when the user pastes a review comment and asks whether it holds ("このコメント妥当?", "レビュー対応したい", "address the review"). Never pushes.
argument-hint: "[PR URL or number; omit for the current branch's PR]"
---

The author owns every decision; you own the facts. A review comment, whether from a person or a bot, is a claim to verify, not an order to follow. Fixes go into the commit they belong to, so the PR keeps its handful of meaningful commits.

Say in one line what you loaded: the PR, how many unresolved threads, and where the branch stands relative to its base.

## Load

- Resolve the PR: the argument, else `gh pr view --json number,headRefName,baseRefName,url` for the current branch. Confirm the checked-out branch is the PR head and the working tree is clean before any rewrite.
- Fetch unresolved review threads with `gh api graphql` (`reviewThreads` with `isResolved == false`; keep `path`, `line`, the thread `id`, and each comment's `databaseId`, author, and body). Present them in file order, oldest thread first.
- A comment pasted into the chat ("In `<path>` at line N — review comment from @<login>: ...") joins the same ledger as the next item; match it to a fetched thread when one exists so the reply can land there.
- Read the whole discussion first. A reply the author already gave, or a change already made, counts as settled.

## One comment per turn

```
**[N/M] <path>:<line> @<login>**

> <the comment, trimmed to the claim>

Checked: <what holds and what does not, each with file:line, a command's output, a spec clause, or the primary source>
Options: <a> / <b> / ...
➡️ <recommendation> — fold into <sha> <subject>  (or: new commit, because <reason>)

accept / modify / reject?
```

Then stop. Verify before judging: read the code the comment points at, what calls it, and the upstream docs or source when the claim rests on a tool's behavior. A wrong premise is called out with evidence regardless of who wrote it; a correct and important point is said to be so. Do not soften or inflate. When the reviewer is right about the problem but not the fix, say both.

Pick the landing commit by reading `git log --oneline <base>..HEAD` and the history of the touched lines. The commit that introduced the thing under review is the default; a change that no existing commit explains gets a new commit with its own message.

## After the decision

- **accept / modify**: implement, `git add` the files by name, `git commit --fixup=<sha>`. Then, in this order:
  1. `git fetch` the remote, take the base freshly: `git merge-base HEAD origin/<default>`. Never reuse a base from earlier in the session; another session may have rebased the branch since.
  2. Note the current tip and the branches stacked on it (`git branch --contains HEAD`, minus the current branch).
  3. `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>`.
  4. `git diff <old tip> <new tip>` must show the fix and nothing else; `git log --oneline <base>..HEAD` must show the same commits as before. If not, stop and show the user before touching anything else.
  5. Each stacked branch follows with `git rebase --onto <new tip> <old tip> <branch>`, then the same diff check on that branch. Return to the PR branch.
- **reject**: no commit. The reply carries the evidence.
- Either way, draft the reply in the author's voice and in the language the author uses on that PR: the part of the comment that is right comes first, then what was done or why not, in as few sentences as the point allows. Mark anything you added that the author did not say.

Post a reply only when told to, with `gh api` against the thread's comment id; resolve a thread only when told to. Never push. When the branch is ready, say so and name the command the user would run (`git push --force-with-lease`).

## Ledger

Keep it in three states: open / settled (decision, landing commit, replied or not) / rejected (reply drafted or posted). Re-list it only when asked, and once at the end:

```
| # | comment | decision | commit | reply |
```

Offer to save the final ledger to the project's memory when the review is done or the session pauses, so a later session can tell what was addressed and what was still owed.
