## 背景
<One or two lines: which part of the parent's spec this carries, with the link. The reasons stay in the parent.>

## ゴール
<The end state of this piece in one paragraph. An ordering constraint goes here, and between siblings also as blocked-by.>

## 変更方針
- **<a decision only this issue makes>**: <what and why, one or two lines>
- **<a point a person will decide later>**: 人が決める

## 完了条件
- [ ] <an observable state the diff does not show, one per line>

---

<details>
<summary>🤖 エージェント向け指示</summary>

### 前提の確認
- <a condition to verify first; if it fails, stop and report in the session, not on this issue>
- 作業ブランチは `origin/main` から `<branch>` を切る

### 手順
1. <concrete step, naming the files and the shape of the change>
2. 変更量を見て(`git diff --stat origin/main`)、[Google の small CLs の指針](https://google.github.io/eng-practices/review/developer/small-cls.html)を目安に大きければ分割案を本 issue にコメントして待つ
3. push 前に work-issue のレビューを、妥当な未対応の所見が出なくなるまで(上限 2 周)。その後 `REVIEW.md` の基準でセルフレビュー
4. draft PR を作る(base: main、#<parent> と本 issue を参照)

### 検証(エージェントが実行する)
```bash
<command>   # 期待: <result>
```

### 検証(人が実行する。エージェントはコマンドと期待結果を提示する)
```bash
<command that needs credentials or a live environment>   # 期待: <result>
```

### 制約
- push・draft 解除・apply・merge は人が行う
- issue に無い判断は推測せず、本 issue にコメントして止まる
- <what must not change>

### 報告
- PR の URL（未 push なら commit SHA と push コマンド）、変更の要約、人が実行する検証コマンドと期待結果、確認したこと、issue が覆っていない判断はセッションに提示する。本 issue へのコメントには書かない
- 人が結果を伝えたら、完了条件を更新して issue を閉じる

</details>
