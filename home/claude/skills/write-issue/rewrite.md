# Rewriting an existing issue

For an issue whose body is replaced as a whole, such as one written before the current templates. The draft is a file in the worktree that the user and you both edit, and GitHub changes only on the user's approval.

1. **Baseline.** Save the current body to a draft file in a place inside the worktree that git ignores (which directory is the repository's choice), and stage it, so that the index holds the body as GitHub has it. Nothing there is committed.

   ```bash
   gh issue view <N> --json body --jq .body > <draft> && git add -f <draft>
   ```

2. **Check against the spec.** Read the parent's spec and the decisions in the sibling issues. List where the current body contradicts them and what it leaves out.
3. **Settle** what the user decides, in one message, as Showing in chat sets out.
4. **Draft** the new body in the same file from the current template, and open it in the file pane. When the pane cannot open it, as when the session is not in a window, put a link to the file in the reply. In chat, show only the decisions and the change from the baseline, `git diff <draft>`.
5. **Share the file.** The user may edit the draft at any time. Read it again before each rewrite and before applying, and keep their edits: write changes into the file, never your whole version over it. Their edits then show up in the diff beside yours.
6. **Apply** on approval, the file as it stands. First name what the new body drops from the old one. The staged baseline is the old text that `gh-body-edit` checks GitHub against:

   ```bash
   git show :<draft> > <scratchpad>/<N>-baseline.md
   gh-body-edit issue <N> --replace <scratchpad>/<N>-baseline.md <draft>
   git add -f <draft>
   ```

   When GitHub's body changed after the baseline, `gh-body-edit` stops: fetch the body again and show the user the difference. After applying, confirm that the body on GitHub equals the draft. Staging the draft again makes the next round start from what GitHub now has.
