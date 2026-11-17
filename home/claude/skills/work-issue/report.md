# The report page

One page for the person who ran you, read top to bottom in the order a reviewer comes to understand it: what it is for, how it works, the code in the order its parts depend on each other, and what shows it works. Five sections, in this order.

## 1. 冒頭

Readable in thirty seconds:

- the issue's purpose in one sentence
- where it stands: the PR URL, or the short SHA and the push command; the verifier's verdict; what is left to the person, one line each
- the 要確認ポイント from the decision log, numbered, one line each, each a link to its callout in section 3; 「なし」 when there are none

## 2. 全体像

- 背景: the part of the system the change touches and why the change was needed, for a reader who has not opened the issue
- the change in plain words, before any code, with a before/after diagram when the contrast is the point
- a map by layer: each layer the change touches, its files, and what changed there in one line

## 3. 読む順の diff

Group the hunks by concept and order the groups by contract: types, traits, and schema or migrations first, then the implementation, then the tests. In layered code this runs domain, use case, infrastructure, handler. A change with no such layers, such as prose or configuration, is ordered the way a reader needs it to follow the change. Each group opens with why it changed, from the log and the issue.

Show every hunk except the mechanical ones, taken from `git diff origin/<base>...HEAD` and escaped, never retyped.

Each 要確認ポイント is a callout right above its hunk, with the log entry's four lines. 細部 and 却下 entries, and the minor review findings left unfixed, sit at their hunk as plain notes, styled apart from the callouts.

## 4. 動作の証拠

The verification record from SKILL.md, with one more line, 未検証: each 未証明 entry, linked to its callout; 「なし」 only when a command or test shows every behavior the change adds.

## 5. 機械的な差分

Renames, lock files, generated files such as query caches and snapshots, and formatting-only hunks: each named with one line on why it changed, its hunks collapsed in a `<details>`.

## Page

These follow the explain-diff skill's page rules, so change the two together.

- One HTML file with its CSS inline.
- A code or diff block is a `<pre>`, or an element whose CSS sets `white-space: pre` or `pre-wrap`; anything else collapses its line breaks. Check every block before handing the page over, by reading the HTML itself: count the code and diff blocks against the `<pre>` elements, and check that the tags balance. Do not open the page in a browser for it.
- Diagrams are built from HTML and CSS, one or two kinds reused through the page.
- opening-a-pr's rules on linking terms and on values not yet measured hold for the page too.

## Do not

- Do not draw a diagram as ASCII art.
- Do not load fonts, scripts, styles, or images from anywhere else.
- Do not use tabs for the page's top-level structure.
- Do not flag anything as a 要確認ポイント beyond what the decision log marks as one.
- Do not publish the page, or attach it to the PR or the issue.
