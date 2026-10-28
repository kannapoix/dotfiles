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

### 検証(エージェントが実行する)
```bash
<command>   # 期待: <result>
```

### 検証(人が実行する。エージェントはコマンドと期待結果を提示する)
```bash
<command that needs credentials or a live environment>   # 期待: <result>
```

### 制約
- <what must not change>

</details>
