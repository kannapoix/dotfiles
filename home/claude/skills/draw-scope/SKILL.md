---
name: draw-scope
description: Draw a fixed-layout scope diagram of an architecture or tracking issue and the stacked PRs under it, as PNGs to paste into GitHub. Use when the user asks for a scope diagram, an overview of what an issue or PR covers, or a picture of a stack (/draw-scope, "担当範囲を図にして", "issue に貼る全体図", "stacked PR の範囲"). Also use it when reviewing a tracking issue or a stack and a shared picture of who adds which part would help. Do not use it for one-off charts, interactive HTML, or Canvas; those cannot be pasted into a GitHub body.
argument-hint: <issue or PR URL>
---

A scope diagram is one picture of a system, repeated. The first picture is the whole system. Each later picture is the same placement, with a different part emphasized, so a reviewer can flip between an issue and its PRs and see the scope move. The pictures are PNGs because they are pasted into GitHub. An interactive page cannot go there.

Say in one line what you are drawing: the scope issue, its parent if it has one, and the PRs in stack order.

## Look before you assign a box

The title is not evidence. Read the body, and the comments, because a later comment overrides the body where they disagree.

- A PR URL: the issue it closes is the scope issue. `gh pr view <N> -R OWNER/REPO --json closingIssuesReferences,baseRefName,headRefName,title,body,files`
- An issue URL that has implementing PRs: that issue is the scope issue. Its parent, if it has one, is where the overview goes.
- A parent issue with several sub-issues, and the user did not say which: ask which sub-issue. Do not fan out across all of them.

```bash
gh issue view <N> -R OWNER/REPO --json title,body,url
gh api graphql -f query='{ repository(owner: "OWNER", name: "REPO") { issue(number: N) { parent { number title } subIssues(first: 50) { nodes { number title state } } } } }'
gh pr list -R OWNER/REPO --search 'issue:N' --state all --json number,title,baseRefName,headRefName,state
```

Stack order comes from branches, not from PR numbers. Order the PRs so each one's `baseRefName` is the previous one's `headRefName`. The first one's base is the branch the issue targets. If they do not form that chain, stop and ask. A merged PR stays in the order: "already in" means earlier in the stack, not "still open".

For each PR, read the body and `gh pr diff <N> -R OWNER/REPO --name-only`. A box belongs to the PR that introduces it. A later PR that edits the same files does not take the box. Write the assignment in the conversation before drawing:

```text
- <box>: #<pr> — <file or sentence that shows this PR adds it>
- <box>: outside #<issue> — <why it is still in the picture>
```

A row with no file and no sentence is a guess. Ask about that row instead of drawing it.

## The pictures

One placement, then views that only change emphasis:

- **Overview.** Every box in its resting style. This goes on the parent issue. If the scope issue has no parent, it goes on the scope issue, and you do not also post a second picture that paints every box blue.
- **Issue scope.** Boxes the issue owns are blue. The rest stay visible and gray.
- **One picture per PR.** Paint from the stack, in this order. Do not color a box by hand.

```text
青い塗り     = この PR が追加する
通常の実線   = 先行 PR ですでに入っている
薄い破線     = 後続 PR。まだ入っていない
グレー       = 対象 issue の範囲外
```

When the issue is in Japanese, the legend is `この PR (#N)`, `先行 PR で入っている`, `後続 PR。まだない`, `#N の範囲外`. Omit a swatch that does not appear. Arrows and coordinates stay put between views. A box the architecture itself marks as not built yet is dashed in the overview and when it is gray.

## Draw

Write `~/Downloads/<owner>-<repo>-<issue>-scope/draw.py`. If it is already there, edit it and keep the coordinates. The script owns the layout and writes one SVG per view next to itself. Colors:

```python
plain = ("#ffffff", "#475569", 1.2, None)       # overview
this  = ("#dbeafe", "#2563eb", 2.2, None)       # blue fill
done  = ("#ffffff", "#334155", 1.6, None)       # already in
later = ("#f8fafc", "#cbd5e1", 1.0, "6 4")      # not yet
out   = ("#f8fafc", "#cbd5e1", 1.0, None)       # outside the issue
```

`this` and `done` get a badge with the PR id. `this` is a blue badge, `done` is a white one. Set the SVG `font-family` to `Noto Sans CJK JP`.

```bash
python3 ~/Downloads/<owner>-<repo>-<issue>-scope/draw.py
for f in ~/Downloads/<owner>-<repo>-<issue>-scope/*.svg; do
  scope-diagram-png "$f" "${f%.svg}.png"
done
```

`scope-diagram-png` writes one PNG at the SVG's own pixel size. It is installed by this repo's home-manager config. It loads Noto Sans CJK JP at weights 400 and 700. If it is missing, say so and stop. The user switches home-manager. Do not use another rasterizer.

## Show the PNGs, then wait

Put each PNG in the conversation, with the path of `draw.py` and which issue or PR would receive which file. Stop there. A correction is an edit to `draw.py` and a re-run, not an upload.

## After they accept

Upload each PNG, then insert it under the opening line of the body it belongs to. Do not rewrite the body. The overview goes on the parent (or on the scope issue, when it has no parent). The issue-scope picture goes on the scope issue. Each PR picture goes on that PR.

```bash
repo_id=$(gh api repos/OWNER/REPO --jq .id)
name=$(basename "$png")
gh api --method POST \
  -H "Content-Type: image/png" \
  "https://uploads.github.com/user-attachments/assets?repository_id=${repo_id}&name=${name}&content_type=image/png" \
  --input "$png" \
  --jq .url
```

The markdown is one image whose alt text is the view title. End the new-text file with a blank line. On a first insert, the anchor is the opening line:

```bash
gh-body-edit -R OWNER/REPO issue 123 \
  --append-after anchor.md image.md
```

On a re-run, `--replace` that first image line. If the first image is not one of these diagrams, stop and ask. If the command prints `ABORT`, stop and show the reason. Do not write the whole body with `gh issue edit` or `gh pr edit`.
