## この issue でやること
<One paragraph that reads without opening the parent: the state this issue brings about, and a link to the part of the parent's spec it carries. A fact the work depends on is stated with its link: what another issue put in place, and every constraint set on it anywhere above or beside this issue (an ancestor issue, a sibling, a design doc), such as where it lives or how it may be referenced. The execution session reads only this issue and its parent, so a constraint left in a grandparent or a sibling does not reach it. An ordering constraint goes here, and between siblings also as blocked-by.>

## 何を守るか
<What breaks or goes unnoticed without this, and what it leaves alone because something else already covers it. The reasons behind the spec's decisions stay in the parent.>

## 変更方針
- **<what a decision only this issue makes is about, as a noun>**: <the decision and why, as a whole sentence; one or two lines. What must not change is a line here too: 「…はしない」>
- **<what a person will decide later is about, as a noun>**: <what is open, as a question>は人が決める

## 確かめ方
- <one or two conditions that show the diff is right, checkable by reading or running it, such as a test that passes or a behavior in a named case, an API test the agent can run included; name the test or the behavior, not the command>

## 完了条件
- [ ] <a state the diff does not show, one per line, in the order it comes about. For an infrastructure change: applied to dev and checked there, before review and merge; the steps that get there go in the PR description, not here. A check that needs the merged state, such as making a job a required check, goes last and says what it waits for.>
