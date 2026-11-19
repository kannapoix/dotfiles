---
name: japanese-writing
description: Rules for Japanese text that someone else reads - issues, PR descriptions, review comments and replies, code comments, docs, Notion pages, and reports. Read before writing or revising such text in Japanese, and when the user says the Japanese reads wrong ("日本語が変", "わかりにくい"). Other skills cite its rules by number.
---

> The numbered, citable rule list follows the shape of poteto's [unslop](https://github.com/cursor/plugins/blob/e1cc03121a0e71129a4fb730d7c5528a0a3e43c8/pstack/skills/unslop/SKILL.md) skill. The rules themselves are the user's own corrections.

Each rule below came from a correction the user made to Claude's Japanese. Apply them to every line of the text: a heading, a table cell, a bullet, or a code comment as much as a sentence, since a reader may read any line alone. A rule's examples show what it means; they do not set its scope.

Rule numbers are stable ids that other skills cite. A removed rule leaves a gap, and a new rule takes the next number. A correction to Japanese wording that should hold from now on is added here as a new rule, or widens the rule it should have fallen under, rather than living in another skill.

## Words

1. Use the word Japanese engineers use, not a word-for-word rendering of the English, which makes the reader translate it back: 通知, not 知らせ; 発火する, not 鳴る; バージョン, not 版. A verb or a metaphor can be a calque as much as a one-character noun. When unsure, take the word the vendor's Japanese documentation uses, or keep the English term (severity).
2. One name per thing. Once a thing has a name in the text or in the project, repeat that name instead of switching to a synonym.
3. Name the concrete thing, such as the product, the component, or the mechanism, rather than a general description of it. Where a number or a short calculation shows the point, give it.
4. A technical term is there for the reader. The vendor's term for something the reader works with is right. A term borrowed from another field to sound precise, or a detail the reader does not need to follow the point, is left out.
5. An identifier, such as a job, setting, or function name, comes only after the plain words that say what it is, in parentheses: 「再試行の上限回数(`max_retries`)」. A reader who has not seen the code reads the words, not the name.

## Sentences

6. Say whose thing it is, who acts, and what it acts on, unless the line before settles it. 「再起動が続く」 does not say what restarts; 「許可すると」 says neither who allows nor what. The one who acts is a named thing, never an action noun: 「判定が」 reads as if 判定 acts.
7. Repeat the noun instead of これ, それ, or その〜 when two things could be meant, such as 「その設定」 with two settings in view.
8. Where の could mark either the one who acts or the thing acted on, use the particle that says which: 「ユーザーによる削除」 or 「ユーザーを削除すること」, not 「ユーザーの削除」.
9. Put a reason in the sentence it explains, before the conclusion or joined to it. Do not invert it into a trailing fragment: 「…保存に失敗する。容量が足りないため」.
10. One idea per sentence. Split a sentence the reader has to read twice; a goal or condition with several parts becomes short bullets.
11. A bullet or table cell that states something ends in its predicate: 「中身が元のファイルと同じになる」, not 「中身が元のファイルと同じ」.
12. A bold label with a colon is a noun naming what the line settles (「**通知**」「**既存の設定**」), followed by a whole sentence carrying the point and its reason. A label that holds the point itself leaves only 「〜ため」 or a fragment after it, and the line no longer reads on its own.

## Notation

13. No space between a numeral and the counter or kana after it: 1つ, 2回目, 29文字. Keep a space after a reference such as `#123`, and between Latin words and Japanese (PR 上で).
