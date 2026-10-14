---
name: one-by-one
description: Settle a list of items one at a time. Use when the user hands over several questions, decisions, or fixes and wants them worked through in order rather than all at once ("順番に", "一個ずつ", "one at a time").
argument-hint: [the items, or "the list above"]
---

Work the list as a **ledger**: numbered items, each open, settled (with its landing), or dropped. Keep the user's order; if you produced the list, order by importance.

Take **one item per turn**. Give it the full treatment: what you found, the options if any, your recommendation, and the single decision you need. Then stop. Do not mention the next item, and do not mention that later items are being investigated.

Format:

```
**N. <item>** (N of M)

<assessment and evidence>

➡️ <recommended decision>
```

The gap the user feels is the one after they settle an item, before the next one is ready. Close it by having the next item's facts already gathered. On the same turn you present the current item, start a background subagent on the next open item, and end the turn without waiting for it. Give the subagent the item and the context it needs, and have it return what it found, the options, a recommendation, and the decision to ask. It changes nothing: no edits, no landings, no decisions applied. Skip the prefetch when no next item exists, or when the next item's facts depend on the decision still open — that brief would answer the wrong question. Keep one item ahead, not the rest of the list; a later landing often changes what follows.

When the brief arrives and the user has not answered, keep it and send nothing. A finished prefetch is not a turn.

When the user answers, act on the decision if it implies an action, record the landing in one line, and move to the next open item. If the brief is in and still matches that item, present it from the brief and start the following prefetch the same way. If the brief is still running and the landing left the question unchanged, present only when it arrives: don't investigate a second time, and don't post a holding message. If there is no usable brief, investigate on this turn, then present. If the answer leaves the item open, stay. The user can jump, skip, add, or ask for the ledger at any time; drop a brief that is no longer the next item.

Facts are yours to find; decisions are the user's. Do not act on later items before their turn.

The list is done when nothing is open. Close with one recap of every landing.
