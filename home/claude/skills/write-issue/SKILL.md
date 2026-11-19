---
name: write-issue
description: Settle a spec on a parent issue with the user, then cut it into sub-issues that a separate execution agent can carry out from the issue alone, and create them under the parent. Use in a planning session when work is being shaped or handed to an execution agent ("issue にして", "spec にして", "タスクに分けて", "sub-issue を切って", "write an issue for this"), when a changed decision has to be carried into the sibling issues, and when an existing issue is rewritten in the current form ("今の形式に書き直して"). Stops for approval after each stage and creates nothing before it. Counterpart of work-issue.
argument-hint: "<parent issue number or the goal, or an existing issue to update or rewrite>"
---

A sub-issue is thin only when the spec above it is thick. The parent issue holds the spec: why the work exists, what was decided and why, what is uncertain, and how correctness will be shown. Each sub-issue says in its own words what it is for, links to the parent for the reasons behind the decisions, and carries only the decisions and checks that are its own. The execution session sees only the issue and its parent; whatever this session knows and both leave out becomes a guess or a stop over there.

Say in one line what you are doing: "#N を spec にしてタスクに分ける", an update of #M, or a rewrite of #M.

## Stages

Work in numbered stages. At the end of each one marked **Stop**, wait for the user's approval. Approval of one stage is never approval of the next, and "looks good" on the spec does not approve the cut.

The two templates in this skill's directory, `spec.md` for the parent and `sub-issue.md` for each piece, say under each heading what belongs there. Read the template before drafting from it, and read Writing below before any body.

### 1. Place

The spec lives in the parent issue's body. Read the parent if it exists: body, comments, its sub-issues, and the status comment (Status below); with a status comment, resume at the first stage not approved and say where you resume. With no parent yet, the spec becomes a new issue at stage 2's approval. Read the code, docs, and design notes the work touches, and the project's conventions (CLAUDE.md, memory).

### 2. Spec — Stop

Draft from `spec.md`. Start from the headings and a few short bullets under each, and grow it with the user; do not arrive with a finished document.

End by proposing whether stage 3 is needed (several systems touched, a flow across them, or something that could break far away) and let the user decide. On approval, write the spec into the parent (Writing to GitHub) and create the status comment; say before writing that both will be written. When the parent already has a body, name what the spec drops from it before writing.

### 3. Mechanism — Stop, only when the user asked for it

Fill the spec's 仕組み section.

### 4. Cut — Stop

Cut the spec into pieces, each closed by one PR and checkable on its own. Prefer a narrow path through every layer over one layer at a time; a wide mechanical change goes expand, migrate in batches, contract. Prefactoring comes first.

Show the cut as a numbered list. For each piece, first in plain words: what it does, why it is needed, and where it stands now (not started, in progress, already asked of someone). Then its title, the sibling that must finish first (or none), and what it delivers. A bare list of titles cannot be answered. Ask once, in one message, whether the granularity is right, whether each ordering is real, and what to merge or split.

- Work a person does after merge is a line in the parent's 完了条件, not a piece.
- Work already asked of a person is not a piece; when the parent's completion waits on it, it is a line in 完了条件.
- A sibling must finish first only when this piece needs it merged. Pieces that only have to be checked together, such as a script and the data or infrastructure it acts on, are checked on one piece's branch before either merges, so neither blocks the other; the order comes from checking before merging, not from which code is written first. Both pieces' 完了条件 say what is put in place first, on which piece's branch the check runs, and that both merge once it passes.
- Work no PR can close splits into a parent that holds it and a child the PR closes.
- Nothing sits between the parent and a sub-issue. A problem found on the way is its own issue, not a piece.

### 5. Draft the sub-issues

Draft every piece from `sub-issue.md`, each in its own file in the scratchpad. A piece with no 確かめ方 condition is not ready to draft: go back to the cut.

### 6. Check

Run this list yourself and fix what it finds before showing anything:

- Coverage: every decision and completion condition in the spec lands in some sub-issue or in the parent's 完了条件, and every constraint an issue above the parent or a sibling set on what a piece uses lands in that piece.
- Consistency: the siblings use the same terms and do not contradict each other or the spec.
- Step scan: no line that decides nothing, and no line that transcribes code.
- Proportion: the sub-issues together are not several times longer than the spec.
- Review focus: for each input or failure the spec implies but does not discuss, the one most likely to bite has a test owned by some sub-issue.
- Writing: every line, a heading, table cell, or bold label included, holds to the japanese-writing skill and to Writing below.

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

Find the comment, then change only the lines that moved, as with a body (Writing to GitHub):

```bash
gh api repos/<owner>/<repo>/issues/<parent>/comments --jq '.[] | select(.body | startswith("<!-- write-issue-status -->")) | .id'
gh-body-edit comment <id> -R <owner>/<repo> --replace old.md new.md
```

## Writing

Write issues in Japanese, following the japanese-writing skill. The rules below are the ones only issues need, and they too hold for every line of a body.

- The human sections hold decisions only and read without the code: behavior, contracts, and their reasons. Job names, lists of paths, and conditional expressions stay out; the execution session finds them in the code. The issue is what a reviewer reads from the PR, and later the record of why, so it has to outlast the code.
- Short nested bullets. Start as a small skeleton; add a table or a diagram only when asked, apart from the overview table of the next rule.
- A body that settles three or more decisions of the same kind, such as alerts, endpoints, or jobs, lists them first in one overview table (name, weight, condition), then gives each its own `###` with its reason, and puts the rules every item shares in one section instead of repeating them. A policy the team has to see gets a section of its own, headed for that reader. The template's headings then serve as a checklist of what to cover, except 確かめ方 and 完了条件, which stay as headings. Show this outline and ask before writing the body in it.
- The one who acts (japanese-writing rule 6) is defined once, as a named thing such as 「定期的に動く監視ジョブ」, and that name is used throughout.
- A point left to a person is a question about what is open (「**失敗の通知**: どう通知するかは人が決める」). A topic alone (「**移行が終わるまで**: 人が決める」) reads two ways.
- 確かめ方 and 完了条件 are bullets like any other, so each ends in its predicate (japanese-writing rule 11).
- A term is linked to its official documentation at its first occurrence; open the page and confirm the term is there first.
- Title: a verb and its object that someone without the background understands.

## Showing in chat

Show only what the user decides, as rendered markdown. Bundle the questions that are the user's to decide into one message and settle everything else yourself; explain each option or list item in plain words before asking about it. For sub-issues, show each one's title and every section. End with at most two next steps on the main line of the work, without the small tasks that follow from them.

## Writing to GitHub

Create nothing before the stage's approval. The user edits issues on the web at the same time, so a body changes only through `gh-body-edit issue <N> --replace old.md new.md` (or `--append-after anchor.md new.md`, or `--delete old.md`; `gh-body-edit comment <id>` takes the same for the status comment), which touches only that part. Keep the title unless asked.

## Update

When a decision changes, change the spec first, then every sub-issue it reaches, every section in the same edit. Show the proposal as a draft is shown, list the sibling issues it reaches, and update them together on approval.

To rewrite an existing issue's body as a whole, as for one written before the current templates, follow [rewrite.md](rewrite.md): the draft is a file the user can edit too, and it is checked against the parent and the siblings first.

## Measure

Two numbers tell whether the spec and the issues were complete: how many times an execution session stopped for a decision they did not cover, and how many times a body was rewritten (`userContentEdits { totalCount }` on the issue in GraphQL). Both should fall.

## Do not

- Do not put steps or commands in a sub-issue: which files to touch, in what order, and how to run the checks are the execution session's to find.
- Do not add sections the templates lack, such as 人のゲート, スコープ外, or 依存. Order goes in ゴール (この issue でやること in a sub-issue) or 変更方針, and between siblings also as blocked-by; something deliberately not done is a 変更方針 line with its reason.
- Do not copy work-issue's own rules (the size check, the review, push, the draft PR, the report, when to stop) into an issue: a copy goes stale when work-issue changes, and the issue then contradicts it.
- Do not write history into an issue, such as keeping one commit, amending, or squashing; CLAUDE.md sets that by the pull request's stage.
- Do not write a value before it is measured; write 「未計測。#N で計測して決める」.
- Do not paste a body into chat as a fenced block.
