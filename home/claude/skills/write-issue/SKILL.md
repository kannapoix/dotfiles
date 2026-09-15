---
name: write-issue
description: Write a sub-issue that a separate execution agent can carry out with no context beyond the issue itself - decisions for people on top, a fixed "🤖 エージェント向け指示" block below - and create it under its parent with gh and the sub-issue API. Use in a planning session when work is being handed to an execution agent ("issue にして", "sub-issue を切って", "write an issue for this"), and when a changed decision has to be carried into the sibling issues. Counterpart of work-issue.
argument-hint: "<parent issue number or the goal, or an existing sub-issue to update>"
---

The execution session sees only the issue. Everything this planning session knows and the issue leaves out becomes a guess or a stop over there, so the issue carries every decision, and only decisions: the "how" goes into the agent block. People read the top; the agent block is collapsed because people review it once and then skip it.

Say in one line what you are doing: a new sub-issue under #N, or an update of #M.

## Prepare

- Read the parent: its body, its completion conditions, and the sub-issues it already has. Cut one sub-issue per completion condition of the parent, directly under it; never create an intermediate grouping issue.
  ```bash
  gh api graphql -f query='{ repository(owner: "<owner>", name: "<repo>") { issue(number: <parent>) { subIssues(first: 50) { nodes { number title state } } } } }'
  ```
- Read the code, docs, and design notes the work touches, and the project's terminology conventions (CLAUDE.md, memory). Point at existing documents instead of restating them.
- A problem you discover on the way (a measurement to take, a guard that is missing, a refactor) is a separate issue, not a section of this one.

## Draft

Produce one draft. Ask only the questions the user has to decide, bundled in one message; settle everything else yourself. Create nothing until the user says the draft is good.

The type. It lives here until the team adopts it as an issue template. The headings are fixed strings; the agent block's heading is what a future automatic trigger will extract.

````markdown
## 背景
<Why this work exists: the parent, what is already in place, what is missing. Facts with links, no history.>

## ゴール
<The end state in one paragraph. An ordering constraint ("before the first tenant lands on prod") goes here.>

## 変更方針
- **<decision>**: <what and why, one or two lines>
- **<a point a person will decide later>**: 人が決める

## 完了条件
- [ ] <observable state, one per line>

---

<details>
<summary>🤖 エージェント向け指示</summary>

### 前提の確認
- <a condition to verify first; stop and comment on this issue if it fails>
- 作業ブランチは `origin/main` から `<branch>` を切る

### 手順
1. <concrete step, naming the files and the shape of the change>
2. 変更量を見て(`git diff --stat origin/main`)、[Google の small CLs の指針](https://google.github.io/eng-practices/review/developer/small-cls.html)を目安に大きければ分割案を本 issue にコメントして待つ
3. push 前に `/code-review --fix` を所見が出なくなるまで(上限 2 周)、その後 `REVIEW.md` の基準でセルフレビュー
4. draft PR を作る(base: main、#<parent> と本 issue を参照)

### 検証(エージェントが実行する)
```bash
<command>   # 期待: <result>
```

### 検証(人が実行する。エージェントはコマンドと期待結果を提示する)
```bash
<command that needs credentials or a live environment>   # 期待: <result>
```

### 制約
- push・draft 解除・apply・merge は人が行う
- issue に無い判断は推測せず、本 issue にコメントして止まる
- <what must not change>

### 報告
- PR の URL、変更の要約、人が実行する検証コマンドを本 issue にコメント
- 人が結果をコメントしたら、完了条件を更新して issue を閉じる

</details>
````

No 人のゲート, スコープ外, or 依存 sections: an ordering constraint belongs in ゴール or 変更方針, a decision left to a person is marked 人が決める in 変更方針, and out-of-scope work is simply absent, or its own issue. When the agent may push, the first constraint names the one branch instead: "push は `<branch>` のみ". Write the issue in the language the repository's issues use.

## Before posting

- Title: a verb and its object that someone without the background understands.
- The human sections hold decisions only; every "how" is in the agent block.
- 手順 prescribes no history: no "keep it to one commit", no amend or squash. CLAUDE.md sets that by the pull request's stage, and an issue that repeats it gets followed past the draft stage too.
- Terms follow the project's conventions.
- Consistent with the sibling issues: same terms, no contradicting decisions.
- Derived problems are separate issues; nothing sits between the parent and this issue.

## Create and link

```bash
gh issue create --title "<title>" --body-file <draft.md>          # prints the URL
parent=$(gh issue view <parent> --json id -q .id)
child=$(gh issue view <url> --json id -q .id)
gh api graphql -f query='mutation($p: ID!, $c: ID!) { addSubIssue(input: {issueId: $p, subIssueId: $c}) { subIssue { number } } }' -f p="$parent" -f c="$child"
```

`replaceParent: true` in the same mutation moves an issue to a different parent. Then offer the execution session: a task chip, or a fresh session, whose prompt is exactly `/work-issue <number>` and nothing else. The issue is the whole brief; extra context in the prompt would hide what the issue lacks.

## Update

The user edits issues on the web too. Fetch the latest body (`gh issue view <N> --json body -q .body`), replace only the affected part, keep the title unless asked, and write back with `gh issue edit <N> --body-file`. When a decision changes, list the sibling issues it reaches and propose updating them together.

## Measure

Two numbers tell whether the issue was complete: how many times the execution session stopped for a decision the issue did not cover, and how many times the body was edited (`userContentEdits { totalCount }` on the issue in GraphQL). Both should fall.
