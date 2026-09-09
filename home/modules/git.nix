{
  programs.git = {
    enable = true;

    ignores = [
      ".DS_Store"
      ".direnv"
      ".devenv"
      ".vscode"
      "**/.claude/settings.local.json"
    ];

    # ~/dotfiles takes session branches by fast-forward only: no merge commits, no PRs.
    includes = [
      {
        condition = "gitdir:~/dotfiles/";
        contents = {
          merge.ff = "only";
          pull.ff = "only";
        };
      }
    ];

    settings = {
      user = {
        name = "UK";
        email = "uenokan@gmail.com";
      };

      alias = {
        push-f = "push --force-with-lease";
        list-alias = "!git config --list | perl -F\\\\. -ane 'printf \"%-20s%s\", split \"=\", join(\".\", @F[1..@F-1]), 2 if $F[0] eq \"alias\"'";
        st = "status";
        sw = "!f () { git branch | sed 's/*//g' | sed 's/ //g' | fzf; }; branch=`f`; git switch $branch";
        sw-remote = "!f () { git branch -r --list  | awk '$1 != \"origin/HEAD\" {print $1}' | cut -d/ -f2- | fzf; }; branch=`f`; git switch -c $branch origin/$branch";
        p = "add -p";
        amend-noedit = "commit --amend --no-edit";
        lg = "log --graph --pretty=tformat:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --decorate=full";
        wt-pr = "!f () { num=$1; [ -z \"$num\" ] && num=$(gh pr list | fzf | cut -f1); [ -z \"$num\" ] && exit 1; branch=$(gh pr view \"$num\" --json headRefName -q .headRefName); dir=\"../$(basename $(git rev-parse --show-toplevel))-pr-$num-$(echo $branch | tr / -)\"; git worktree add --detach \"$dir\" && (cd \"$dir\" && gh pr checkout \"$num\"); }; f";
        sync = "!f () { git pull --ff-only 2>/dev/null && return; echo \"fast-forward failed (remote may have been rebased/force-pushed)\" >&2; printf \"force-sync to remote? [y/N] \" >&2; read ans; case \"$ans\" in y|Y|yes|YES) ;; *) echo \"aborted\" >&2; exit 1;; esac; if num=$(gh pr view --json number -q .number 2>/dev/null); then gh pr checkout \"$num\" --force; else git fetch && git reset --hard '@{upstream}'; fi; }; f";
        rb = "!f () { target=$1; if [ -z \"$target\" ]; then target=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null); fi; if [ -z \"$target\" ]; then target=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | cut -d/ -f2-); fi; if [ -z \"$target\" ]; then echo \"usage: git rb [branch] (could not detect PR base or default branch)\" >&2; exit 1; fi; echo \"rebasing onto origin/$target\" >&2; current=$(git rev-parse --abbrev-ref HEAD); if [ \"$current\" = \"$target\" ]; then echo \"already on $target; nothing to rebase onto\" >&2; exit 1; fi; git fetch origin \"$target\" || exit 1; if git merge-base --is-ancestor \"origin/$target\" HEAD; then echo \"already up to date with origin/$target\"; exit 0; fi; git rebase \"origin/$target\"; }; f";
        land = "!f () { unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR; b=$(git branch --show-current); if [ -z \"$b\" ]; then echo \"detached HEAD; nothing to land\" >&2; exit 1; fi; main_wt=$(git worktree list --porcelain | sed -n '1s/^worktree //p'); target=$(git -C \"$main_wt\" symbolic-ref --short -q HEAD); if [ \"$target\" != main ]; then echo \"main checkout $main_wt is on '$target', expected main\" >&2; exit 1; fi; if [ \"$b\" = main ]; then echo \"already on main; nothing to land\" >&2; exit 1; fi; git -C \"$main_wt\" merge --ff-only \"$b\" || exit 1; echo \"landed $b on main; next: git push origin main\"; }; f";
      };

      core = {
        editor = "vim";
        pager = "delta";
      };
      interactive = {
        diffFilter = "delta --color-only --features=interactive";
      };
      delta = {
        features = "decorations";
      };
      merge = {
        tool = "vscode";
      };
      mergetool = {
        vscode = {
          cmd = "code --new-window --wait --merge $REMOTE $LOCAL $BASE $MERGED";
        };
      };
      init = {
        defaultBranch = "main";
      };
      commit = {
        verbose = true;
      };
    };
  };
}
