---
name: draw-scope
description: Draw diagrams of a tracking issue and its sub-issues, or an issue and the stacked PRs under it, as PNGs to paste into GitHub - architecture, scope, sequence, or data flow, whichever explains the work - with one shared placement and one emphasis view per sub-issue or PR. Use when the user asks for a scope diagram, an overview of what an issue or PR covers, a picture of a stack, or a diagram for an issue body (/draw-scope, "担当範囲を図にして", "issue に貼る全体図", "stacked PR の範囲", "issue に図を貼って"). Also use it when reviewing a tracking issue or a stack and a shared picture of who adds which part would help. Do not use it for one-off charts, interactive HTML, or Canvas; those cannot be pasted into a GitHub body.
argument-hint: <issue or PR URL>
---

These pictures go into GitHub issue and PR bodies, so they are PNGs; an interactive page cannot go there. The design is yours: the kind of diagram (architecture, sequence, data flow, or whatever explains this work best), the layout, the colors, the legend, and any notes. What is fixed is below.

Say in one line what you are drawing: the issue at the top, which issues or PRs get a view, and in what order.

## What gets a picture

- **A parent issue with sub-issues**: an overview on the parent, and one view per sub-issue on that sub-issue. If the user named only some sub-issues, draw views for those.
- **An issue implemented by stacked PRs**: a view of the issue's scope on the issue, and one view per PR on that PR. If the issue has a parent, the overview goes on the parent. If it has none, the issue's own picture is the overview; do not also post one that highlights everything.
- **A PR URL**: the issue it closes is the one to draw; continue as above.

The sub-issues or PRs that get a view are the owners. Every part of the picture belongs to exactly one owner, or to none: already there, outside the work, or left for later.

## Look before you assign a part

The title is not evidence. Read the body, and the comments, because a later comment overrides the body where they disagree.

```bash
gh issue view <N> -R OWNER/REPO --json title,body,comments,url
gh api graphql -f query='{ repository(owner: "OWNER", name: "REPO") { issue(number: N) { parent { number title } subIssues(first: 50) { nodes { number title state } } } } }'
gh pr list -R OWNER/REPO --search 'issue:N' --state all --json number,title,baseRefName,headRefName,state
gh pr view <N> -R OWNER/REPO --json closingIssuesReferences,baseRefName,headRefName,title,body,files
```

Stack order comes from branches, not from PR numbers. Order the PRs so each one's `baseRefName` is the previous one's `headRefName`. The first one's base is the branch the issue targets. If they do not form that chain, stop and ask. A merged PR stays in the order: "already in" means earlier in the stack, not "still open".

For a PR, read the body and `gh pr diff <N> -R OWNER/REPO --name-only`. A part belongs to the PR that introduces it; a later PR that edits the same files does not take it. For a sub-issue, the part belongs to the sub-issue whose body says it builds it. Write the assignment in the conversation before drawing:

```text
- <part>: #<owner> — <file or sentence that shows this owner adds it>
- <part>: outside #<issue> — <why it is still in the picture>
```

A row with no file and no sentence is a guess. Ask about that row instead of drawing it.

## What each view must get across

A reader looking at one view, without the issue text, should be able to tell:

- which parts this owner adds, and which parts are someone else's or already there;
- what exists today and what is not built yet;
- the order the owners can go in, when that order matters and the parts alone do not show it;
- what this owner's work includes that the picture does not show, when there is such a thing.

Write the labels in the language of the issue.

## Constraints

- Every view shares one placement: the same parts, positions, and arrows. Views differ only in emphasis. Render all of them from one script, so the placement cannot drift between views.
- In a PR view, parts from earlier PRs in the stack are already in, and parts from later PRs are not yet. Derive that from the assignment; do not decide it per picture.
- Set `font-family="Noto Sans CJK JP"` and use font weights 400 and 700 only. The rasterizer loads that face and no system fonts, so any other family renders without glyphs.
- The rasterizer is resvg, which renders static SVG: no `<foreignObject>` and no automatic text wrapping. Break long lines yourself.

## Draw

Work in the session's scratchpad directory, or a `mktemp -d` directory when the session has none. The Write tool cannot create files in `~/Downloads`. If an earlier run left a script under `~/Downloads/<owner>-<repo>-<N>-*/`, copy it into the work directory and edit it there, so the placement already posted stays put.

Run the script so it writes one SVG per view next to itself, then rasterize:

```bash
for f in "$work"/*.svg; do
  scope-diagram-png "$f" "${f%.svg}.png"
done
```

`scope-diagram-png` writes one PNG at the SVG's own pixel size. It is installed by this repo's home-manager config. If it is missing, say so and stop; the user switches home-manager. Do not use another rasterizer.

Read every PNG yourself before showing it: clipped or overlapping text, arrows through labels, de-emphasized parts that are no longer legible. Fix the script and re-render until none are left. Then keep the script and the PNGs with Bash:

```bash
dest=~/Downloads/<owner>-<repo>-<N>-diagram
mkdir -p "$dest"
cp "$work"/<script> "$work"/*.png "$dest"/
```

## Show the PNGs, then wait

Show each PNG to the user in the conversation, with the path of the saved script and which issue or PR would receive which file. Stop there. A correction is an edit to the script in the work directory, a re-render, and a fresh copy, not an upload.

## After they accept

Upload each PNG, then insert it under the opening line of the body it belongs to. Do not rewrite the body.

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
