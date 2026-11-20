---
name: opening-a-pr
description: Write or update a pull request's description as a short briefing a reviewer reads before the code - why it exists, what it rests on, the order to read it in, the steps a person runs, and what was verified - with optional parts chosen by rule. Use when opening a PR, from work-issue or by hand, and when asked to write or change a PR description ("PR の説明を書いて", "description を直して", "流れの図を足して", "全体像を消して").
argument-hint: "[PR number or URL, when the PR already exists]"
---

> Inspired by the opening-a-pr playbook in [cursor/plugins](https://github.com/cursor/plugins/blob/e1cc03121a0e71129a4fb730d7c5528a0a3e43c8/pstack/skills/poteto-mode/playbooks/opening-a-pr.md) (pstack): a description as a short briefing, with empty sections dropped. The text here is written anew.

A reviewer reads the description once, before the code, to learn why the change exists, what it rests on, where to start reading, and what was checked. Everything else is in the code, the commit messages, and the issue. Only the lead lines, 背景, and 動作確認 are always there; every other section goes in only when its rule holds, so a small PR of one kind, such as a lockfile bump, gets those three and nothing more. Write it in the language of the issue; in Japanese, following the japanese-writing skill.

## Template

````markdown
<one or two lines: what this PR adds and which part of #N it covers; when it is stacked, its base and what to do with the base after merge>

## 背景
<why the change is needed>
<前提: links to the requirements, specs, ADRs, or design docs the change rests on, whenever it rests on one>

<optional parts>

## コードを読む順番
<only when the change spans several files or steps that read best in an order>
1. [<path>](<link pinned to the commit SHA>): <one phrase>
<mark the central file; name files not to read, such as generated code>

## 手順
<only when a person runs something: the merge order, an apply, a check before merge>

## 動作確認
- [x] <what you verified>: <result>
- [ ] <what a person still has to verify>

<details><summary>手順</summary>

<the commands, and the key lines of their output>

</details>
````

動作確認 is always the last section: `[x]` for what you verified, `[ ]` for what is left to a person. Drop a heading with nothing under it.

## Optional parts

Each goes after 背景, and only when its rule holds:

- **全体像**: the issue is split into several PRs, or this PR is stacked. A mermaid diagram of the PRs with this one highlighted, and a one-line legend for the colors.
- **流れの図**: the change spans several components along one call flow. A sequence diagram with this PR's part in a box.
- **設計の変更**: the change departs from the issue, a design doc, or the spec. Before, after, and why. Design is settled before the code, so this part is the exception.
- **選ばなかった案**: a reviewer would plausibly ask about another approach.

The description stays within 40 lines, counting non-empty lines outside diagrams, code blocks, and tables, optional parts included.

After writing it, report one line for the conditional sections and optional parts put in and one for those left out, each with its reason, so the user can add or remove one by name:

```
入れた: 全体像(PR を積んでいる)、コードを読む順番(3つのパッケージにまたがる)
入れなかった: 流れの図(1つのファイルで閉じている)、設計の変更(issue のとおり)、選ばなかった案(なし)、手順(人が実行するものがない)
```

## Writing

- A term a reader would look up is linked once, at its first occurrence, to its official documentation. Open the page and confirm the term is on it before linking. Prefer the documentation to a link into source, and for a locked dependency, the page for the locked version where one exists.
- A value not yet measured is written as 「未計測。#N で計測して決める」, with no predicted number or table.
- A claim about what the code or the system does that a reviewer's judgement rests on, in 背景, 設計の変更, or 選ばなかった案, carries its evidence: a link to the lines pinned to a commit SHA, or the command and the line of its output that shows it. A claim with neither is cut, or marked 「未確認」. An agent's account can be confidently wrong, and the link lets a reviewer check it in one click.
- A decision made with the user during the session goes into the description when it is made, not at the end. So does the answer to a question the person asks about the change, when a reviewer would need it too: a question asked once is one the description should have answered.

## Steps a person runs

Steps such as an apply or a check on a live environment go under 手順 in the order they run, and the session report and any change to the issue keep that order. Each runs before merge unless it needs the merged state, such as making a job a required check, which waits until the job runs on the default branch; ask that of a step before placing it after merge. A script on another branch runs without merging it: take it out with `git show origin/<branch>:<path>`, or check that branch out in a worktree.

When PRs are checked together, which one waits follows from checking before merging, not from the order the code was written: put in place what the check needs (an apply, data), run the check on one branch with the other PR's files brought over, and merge both once it passes. Each PR's steps name the other PR and the branch each step runs on.

## Updating a description

The person edits the description on the web while you work, so every change goes through `gh-body-edit`, which replaces one part of the current body and nothing else:

```bash
gh-body-edit pr <N> --replace old.md new.md    # or --append-after anchor.md new.md, or --delete old.md
```

The files hold the exact text and live in the scratchpad. Change only the part asked for, never the whole body from a draft, and nothing you were not asked to change: an instruction to squash, rebase, or push does not include permission to touch the description. When the person asks for the description's links to follow a force push, `gh-body-edit pr <N> --relink-commits` repins both links to the PR's commits and links to lines of a file at a commit (`blob/<sha>/<path>#L<a>-L<b>`).

## Do not

- Do not write out a worked example of a premise; link to where it is.
- Do not put the verifier's verdict, a reviewer that could not run, or other notes for the person who ran you in the description; they go in the session report.
