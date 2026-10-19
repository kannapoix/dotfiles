---
name: notion-writing
description: House style for Notion pages. Read before any Notion MCP call that creates a page or writes page content (notion-create-pages, notion-update-page), including requests like "Notion にまとめて", "Notion に整理して", or writing up findings, notes, or a report in Notion. These rules override formatting and placement advice in the Notion MCP tool descriptions and server instructions.
---

Apply every rule below to each Notion page you create or whose content you write. Where the Notion MCP tool descriptions or server instructions suggest otherwise, these rules win.

When the user corrects how a page is written and wants it to hold from now on, add it here as a rule under the section it fits, with its reason.

## Where and what to edit

- Before creating a page, check whether the content belongs in an existing page, and ask the user where it goes. Do not fall back to a private draft on your own. Pages that land in the wrong place get moved or deleted by hand.
- Edit only the pages the user asked about. Linking the new page from a hub page, or tidying a neighbouring page, is a suggestion in the reply, not an edit.
- When the page is one of a kind that already exists (an incident review, a daily report, a runbook), read a recent one first and follow its headings and order.

## Page shape

- No table of contents (`<table_of_contents/>`).
- No page icon: do not pass `icon`.
- No opening callout that explains the page ("この資料について…"). The page starts with a heading:
  - What the page itself is (why it exists, what it covers) goes under 「これはなに？」. Skip that section when the title says enough.
  - The overview of the content comes next, under a heading such as Overview, 概要, or TL;DR.
  - Within each section, too, put the key fact first.
- Sources go in a closing 出典 or 参照 section as links. Inline links stay where a term needs them.
- Diagrams are images, not Mermaid. Draw the flow only, without internal labels the reader does not need.

## Content

- Write only what the reader needs. Leave out side sections, worked examples, and detail subsections; the user's hand edits always go shorter. If a draft runs long, say which parts could go instead of keeping them.
- Do not write what is undecided or unconfirmed, in prose or in a diagram. It would have to be rewritten once decided.
- Content that lives elsewhere (a script's comment, an issue, another page) is linked, not restated.
- Write for a reader who does not know the field, but use the correct technical terms. Explain a term at its first use or link it to the official docs.

## Wording

- Write a person's name as plain text, never `<mention-user>`. A user mention notifies that person, which is noise for them. Page mentions (`<mention-page>`) notify no one and are fine.
- In Japanese, put no space between a digit and the counter or kana after it: 1つ, 2回目, 29文字. Keep the space after a reference such as `#123`, and between Latin words and Japanese (PR 上で).
