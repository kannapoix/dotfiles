---
name: explain-diff
description: Teach a code change as one HTML page with background, intuition, and a code walkthrough. Use when the user wants to understand a diff, branch, commit, or pull request in depth rather than get a summary of it.
---

> Inspired by Geoffrey Litt's [explain-diff](https://gist.github.com/geoffreylitt/a29df1b5f9865506e8952488eac3d524/126e7fe9eecaafadfe1ac8bb183d135812b608f2) gist (revision `126e7fe`, 2026-07-01). The idea of teaching a change through background, intuition, and code is Geoffrey Litt's, used with thanks. The gist has no license, so this text is written anew rather than copied; keep it that way when updating.

The reader wants to understand the change well enough to review it, build on it, or explain it to someone else. A summary of the diff does not get them there; a page that teaches it does.

## Before writing

Read the change, then the code around it: callers, tests, data shapes, and the configuration it relies on. Work out how the system behaved before, how it behaves now, and why the change was needed. Start the page only once you can state the change's core idea in two sentences. Every statement the page makes about what the code, a neighbouring component, or the design does rests on a file and line, or a passage of the linked issue or design notes, that you read for this page; read those documents, not only the code.

## The page

One continuous page: a title, a summary of two or three sentences, a table of contents, and three sections in this order.

1. **Background.** First a primer on the part of the system involved, for a reader who has never seen it and marked as skippable; then the narrower context the change touches.
2. **Intuition.** The core idea, before any code. Carry it with one small worked example on made-up data, with before and after side by side when the contrast is the point.
3. **Code.** The changes grouped by concept and ordered the way execution or dependencies run, not by file. Name files and lines, and quote only the lines that carry the idea.

Put definitions, invariants, and edge cases worth remembering in callouts. A page in Japanese follows the japanese-writing skill.

## Diagrams and code

Pick two or three kinds of diagram and reuse them through the page instead of inventing a new picture each time: a stripped-down sketch of the screen for a UI change, and boxes and arrows for components and the data passing between them, with sample values on the arrows. Build them, and any list, from HTML and CSS.

A code block is a `<pre>`, or an element whose CSS sets `white-space: pre` or `pre-wrap`; anything else collapses its line breaks. Check every code block for this before handing the page over, by reading the HTML itself: count the code blocks against the `<pre>` elements, and check that the tags balance. Do not open the page in a browser for it.

A label that names a file and lines (`path:a-b`) takes its numbers from the file at the commit being explained, never from memory, since a number written from memory is usually off by one or two. Before handing the page over, check every label against that file: line a is the first line of the block under it, line b the last, and the lines between appear in the file in that order. Fix a label that does not match, and check again until none is left.

## Delivery

The page is a single self-contained HTML file, with its CSS inline. In a chat with no file system, deliver it as an HTML artifact. With a file system, write it to the system's temporary directory, its name starting with today's date (`YYYY-MM-DD-explanation-<topic>.html`) so these pages sort by date, and give the user the full path.

## Do not

- Do not use tabs for the page's top-level structure.
- Do not draw a diagram as ASCII art.
- Do not load fonts, scripts, styles, or images from anywhere else.
- Do not paste the whole diff.
- Do not save the page inside a repository.
