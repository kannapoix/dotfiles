## 背景
<Why this work exists: what is in place, what is missing, and why now. Facts, each with its link; no list of specifics, no history.>

## ゴール
<Success that someone can observe once the work is done, in a few short bullets. An ordering constraint ("before the first user depends on it") goes here.>

## 変更方針
- **<decision>**
  - <why, and what it costs>
- **<something deliberately not done>**: しない
  - <why; only when the reason is itself a decision worth keeping>
- **<what a person will decide later is about, as a noun>**: <what is open, as a question>は人が決める

## 自信のない判断
<The three decisions you are least sure of: the user's chance to step in before code buries the doubt.>
1. <decision>: <why it is uncertain, and what would show it wrong>
2. ...
3. ...

## 確かめ方
- <the seam the tests observe behavior at, the highest one available, existing ones preferred>
- <the oracle: what says the result is right; for a migration, the current behavior pinned first. When no oracle can be named, the work is not ready: say so instead of drafting further.>

## 仕組み
<Only when stage 3 ran: the systems this touches, the flow in order, and what could break elsewhere. No file paths or signatures; the execution session finds those.>

## 完了条件
- [ ] <a state checked after the sub-issues' PRs merge, or a step a person does after merge: one per line. Only what the diffs do not show; what they show is 確かめ方.>
