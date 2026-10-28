---
name: write-issue
description: Settle a spec on a parent issue with the user, then cut it into sub-issues that a separate execution agent can carry out from the issue alone, and create them under the parent. Use in a planning session when work is being shaped or handed to an execution agent ("issue にして", "spec にして", "タスクに分けて", "sub-issue を切って", "write an issue for this"), and when a changed decision has to be carried into the sibling issues. Stops for approval after each stage and creates nothing before it. Counterpart of work-issue.
argument-hint: "<parent issue number or the goal, or an existing sub-issue to update>"
---

A sub-issue is thin only when the spec above it is thick. The parent issue holds the spec: why the work exists, what was decided and why, what is uncertain, and how correctness will be shown. Each sub-issue links there for the reasons and carries only what is its own. The execution session sees only the issue and its parent; whatever this session knows and both leave out becomes a guess or a stop over there.

Say in one line what you are doing: "#N を spec にしてタスクに分ける", or an update of #M.

## Stages

Work in numbered stages. At the end of each one marked **Stop**, wait for the user's approval. Approval of one stage is never approval of the next, and "looks good" on the spec does not approve the cut.

### 1. Place

The spec lives in the parent issue's body. Read the parent if it exists: body, comments, its sub-issues, and the status comment (Status below); with a status comment, resume at the first stage not approved and say where you resume. With no parent yet, the spec becomes a new issue at stage 2's approval. Read the code, docs, and design notes the work touches, and the project's conventions (CLAUDE.md, memory).

### 2. Spec — Stop

Take the headings from `spec.md` in this skill's directory. Start from the headings and a few short bullets under each, and grow it with the user; do not arrive with a finished document.

- 背景: facts with links, not a list of specifics.
- ゴール: success someone can observe, and any ordering constraint.
- 変更方針: each decision and its reason. Something deliberately not done is a decision only when it has a reason worth keeping; write it as one ("…はしない。…だから"), never as a scope section. A point left to a person is marked 人が決める.
- 自信のない判断: the three decisions you are least sure of, each with what would show it wrong. This is where the user can intervene before code buries the doubt.
- 確かめ方: the seam the tests observe behavior at (the highest available, existing ones preferred) and the oracle that says a result is right. For a migration, pinning current behavior comes before changing it; if no oracle can be named, say the work is not ready.
- 完了条件: what is checked after the sub-issues merge, and what a person does after merge.

End by proposing whether stage 3 is needed (several systems touched, a flow across them, or something that could break far away) and let the user decide. On approval, write the spec into the parent (Writing to GitHub) and create the status comment; say before writing that both will be written. When the parent already has a body, name what the spec drops from it before writing.

### 3. Mechanism — Stop, only when the user asked for it

Under 仕組み: the systems this touches, the flow in order, and what could break elsewhere. No file paths or signatures; those belong to the execution session.

### 4. Cut — Stop

Cut the spec into pieces, each closed by one PR and checkable on its own. Prefer a narrow path through every layer over one layer at a time; a wide mechanical change goes expand, migrate in batches, contract. Prefactoring comes first.

Show the cut as a numbered list. For each piece, first in plain words: what it does, why it is needed, and where it stands now (not started, in progress, already asked of someone). Then its title, the sibling that must finish first (or none), and what it delivers. A bare list of titles cannot be answered. Ask once, in one message, whether the granularity is right, whether each ordering is real, and what to merge or split.

- Work a person does after merge is a line in the parent's 完了条件, not a piece.
- Work already asked of a person is not a piece; when the parent's completion waits on it, it is a line in 完了条件.
- Work no PR can close splits into a parent that holds it and a child the PR closes.
- Nothing sits between the parent and a sub-issue. A problem found on the way is its own issue, not a piece.

### 5. Draft the sub-issues

Draft every piece from `sub-issue.md` in this skill's directory, each in its own file in the scratchpad. 背景 links to the parent's spec for the reasons; 変更方針 holds only decisions this issue makes; 完了条件 holds only what the diff does not show. 確かめ方 holds one or two conditions that show the diff is right, such as a test that passes or a behavior in a named case; a piece without one is not ready to draft. No steps and no commands: which files to touch, in what order, and how to run the checks are the execution session's to find. A condition to verify first is a fact in 背景, and what must not change is a 変更方針 line (「…はしない」).

### 6. Check

Run this list yourself and fix what it finds before showing anything:

- Coverage: every decision and completion condition in the spec lands in some sub-issue or in the parent's 完了条件.
- Consistency: the siblings use the same terms and do not contradict each other or the spec.
- Step scan: no line that decides nothing, and no line that transcribes code.
- Proportion: the sub-issues together are not several times longer than the spec.
- Review focus: for each input or failure the spec implies but does not discuss, the one most likely to bite has a test owned by some sub-issue.

Then show the sub-issues (Showing in chat). **Stop.**

### 7. Create

Create in dependency order, blockers first, so blocked-by can name real issues:

```bash
gh issue create --title "<title>" --body-file <draft.md>          # prints the URL
parent=$(gh issue view <parent> --json id -q .id)
child=$(gh issue view <url> --json id -q .id)
gh api graphql -f query='mutation($p: ID!, $c: ID!) { addSubIssue(input: {issueId: $p, subIssueId: $c}) { subIssue { number } } }' -f p="$parent" -f c="$child"
blocker=$(gh api repos/<owner>/<repo>/issues/<sibling> --jq .id)   # the integer id, not the node id that gh issue view --json id returns
gh api -X POST repos/<owner>/<repo>/issues/<number>/dependencies/blocked_by -F issue_id="$blocker"
```

`replaceParent: true` in `addSubIssue` moves an issue to another parent. Update the status comment. Then offer an execution session for each sub-issue nothing blocks: a task chip or a fresh session whose prompt is exactly `/work-issue <number>` and nothing else. The issue is the whole brief; extra context in the prompt would hide what it lacks.

## Status

The state lives in one comment on the parent, edited in place, so the work survives a context reset and the body's edit count stays a measure of the spec. Keep it in the issue's language:

```markdown
<!-- write-issue-status -->
- 段2 spec: 承認 <date>
- 段3 仕組み: 不要 | 承認 <date> | 未着手
- 段4 割り方: 承認 <date> | 未着手
- 段7 起票: #<n>, #<n> | 未着手
- 残る問い:
  - <question, and who answers it>
```

```bash
gh api repos/<owner>/<repo>/issues/<parent>/comments --jq '.[] | select(.body | startswith("<!-- write-issue-status -->")) | .id'
gh api -X PATCH repos/<owner>/<repo>/issues/comments/<id> -F body=@status.md
```

## Writing

Write issues in Japanese.

- No space between a numeral and its counter (「1つ」「2回目」); a space after `#N`.
- The human sections hold decisions only and read without the code: behavior, contracts, and their reasons. Job names, lists of paths, and conditional expressions stay out; the execution session finds them in the code. The issue is what a reviewer reads from the PR, and later the record of why, so it has to outlast the code.
- A term is linked to its official documentation at its first occurrence; open the page and confirm the term is there first.
- Short nested bullets. Start as a small skeleton; add a table or a diagram only when asked.
- No predicted values before measurement: 「未計測。#N で計測して決める」.
- No 人のゲート, スコープ外, or 依存 sections. Order goes in ゴール or 変更方針, and between siblings also as blocked-by.
- 完了条件 holds only what the diff does not show; what the diff shows is 確かめ方. A step a person does before merge goes in the PR description; a check after merge goes in the parent's 完了条件.
- work-issue's own rules (the size check, the review, push, the draft PR, the report, and when to stop) stay out of the issue, since a copy goes stale when work-issue changes and the issue would then contradict it. Infrastructure changes run PR, then the person applies to dev, then checks, then review, then merge, and the person's checks are 完了条件 lines in that order. An API test the agent can run itself is a 確かめ方 condition.
- No history in the issue: no "keep it to one commit", no amend or squash. CLAUDE.md sets that by the pull request's stage.
- Title: a verb and its object that someone without the background understands.

## Showing in chat

Show only what the user decides, as rendered markdown, never a fenced dump of a body. Bundle the questions that are the user's to decide into one message and settle everything else yourself; explain each option or list item in plain words before asking about it. For sub-issues, show each one's title, 背景, ゴール, 変更方針, 確かめ方, and 完了条件. Do not list small derived tasks; end with at most two next steps on the main line of the work.

## Writing to GitHub

Create nothing before the stage's approval. The user edits issues on the web at the same time, so a body changes only through `gh-body-edit issue <N> --replace old.md new.md` (or `--append-after anchor.md new.md`, or `--delete old.md`), which touches only that part and aborts unless the anchor occurs exactly once and the body is still what it fetched. Keep the title unless asked.

## Update

When a decision changes, change the spec first, then every sub-issue it reaches, every section in the same edit. Show the proposal as a draft is shown, list the sibling issues it reaches, and update them together on approval.

## Measure

Two numbers tell whether the spec and the issues were complete: how many times an execution session stopped for a decision they did not cover, and how many times a body was rewritten (`userContentEdits { totalCount }` on the issue in GraphQL). Both should fall.
