{
  programs.git = {
    enable = true;

    ignores = [
      ".direnv"
      ".devenv"
      ".vscode"
      "**/.claude/settings.local.json"
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
