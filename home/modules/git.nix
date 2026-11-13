{pkgs, ...}: let
  # Rebase the current branch onto origin/<target> (the PR's base, else the
  # default branch). When the base branch was rewritten (squashed or rebased
  # under a stacked PR), its old commits are still in this branch; the fork
  # point from origin/<target>'s reflog leaves them out, and an old head given
  # as the second argument does the same where the reflog lacks it.
  gitRb = pkgs.writeShellScript "git-rb" ''
    target=''${1:-}
    old=''${2:-}
    if [ -z "$target" ]; then target=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null); fi
    if [ -z "$target" ]; then target=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | cut -d/ -f2-); fi
    if [ -z "$target" ]; then
      echo "usage: git rb [branch [old-head]] (could not detect PR base or default branch)" >&2
      exit 1
    fi
    current=$(git branch --show-current)
    if [ -z "$current" ]; then echo "detached HEAD; switch to the branch to rebase" >&2; exit 1; fi
    if [ "$current" = "$target" ]; then echo "already on $target; nothing to rebase onto" >&2; exit 1; fi
    git fetch origin "$target" || exit 1
    upstream="origin/$target"
    if git merge-base --is-ancestor "$upstream" HEAD; then echo "already up to date with $upstream"; exit 0; fi
    if [ -n "$old" ]; then
      fork=$(git rev-parse --verify --quiet "$old^{commit}") || { echo "unknown commit: $old" >&2; exit 1; }
      git merge-base --is-ancestor "$fork" HEAD || { echo "$old is not in $current" >&2; exit 1; }
      how="the old head given"
    elif fork=$(git merge-base --fork-point "$upstream" HEAD); then
      how="fork point from the reflog of $upstream"
    else
      fork=$(git merge-base "$upstream" HEAD)
      how="merge base; the reflog of $upstream has no fork point, so if $target was rewritten, run: git rb $target <its old head>"
    fi
    echo "rebasing $current onto $upstream from $(git rev-parse --short "$fork") ($how)" >&2
    dropped=$(git log --oneline "$upstream..$fork")
    if [ -n "$dropped" ]; then
      echo "leaving out the old commits of $target:" >&2
      printf '%s\n' "$dropped" | sed 's/^/  /' >&2
    fi
    echo "carrying:" >&2
    git log --oneline "$fork..HEAD" | sed 's/^/  /' >&2
    if [ -n "$old" ]; then
      git rebase --onto "$upstream" "$fork"
    else
      git rebase --fork-point "$upstream"
    fi
  '';

  # Fold fixup!, squash!, and amend! commits into their targets without moving
  # the base: the base is the merge base with origin/<target> (the default
  # branch, else the argument), which for a stack is its bottom, and
  # --update-refs carries the branches inside the stack along. Catching up
  # with a newer base is git rb's job.
  gitSquashFixups = pkgs.writeShellScript "git-squash-fixups" ''
    target=''${1:-$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | cut -d/ -f2-)}
    if [ -z "$target" ]; then
      echo "usage: git squash-fixups [branch] (could not detect the default branch)" >&2
      exit 1
    fi
    git fetch origin "$target" || exit 1
    base=$(git merge-base HEAD "origin/$target") || exit 1
    short=$(git rev-parse --short "$base")
    if [ -n "$(git rev-list --merges "$base..HEAD")" ]; then
      echo "merge commits since $short; not squashing" >&2
      exit 1
    fi
    if ! git log --format=%s "$base..HEAD" | grep -Eq '^(fixup|squash|amend)! '; then
      echo "no fixup!, squash!, or amend! commits since $short"
      exit 0
    fi
    echo "squashing fixups onto $short (merge-base with origin/$target)" >&2
    tree=$(git rev-parse 'HEAD^{tree}')
    git rebase --autosquash --update-refs "$base" || exit 1
    if [ "$(git rev-parse 'HEAD^{tree}')" != "$tree" ]; then
      echo "the tree changed; compare with: git diff ORIG_HEAD HEAD" >&2
      exit 1
    fi
  '';
in {
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
        rb = "!${gitRb}";
        squash-fixups = "!${gitSquashFixups}";
        land = "!f () { unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR; b=$(git branch --show-current); if [ -z \"$b\" ]; then echo \"detached HEAD; nothing to land\" >&2; exit 1; fi; main_wt=$(git worktree list --porcelain | sed -n '1s/^worktree //p'); target=$(git -C \"$main_wt\" symbolic-ref --short -q HEAD); if [ \"$target\" != main ]; then echo \"main checkout $main_wt is on '$target', expected main\" >&2; exit 1; fi; if [ \"$b\" = main ]; then echo \"already on main; nothing to land\" >&2; exit 1; fi; if ! git merge-base --is-ancestor main \"$b\"; then echo \"main has $(git rev-list --count \"$b..main\") commit(s) not in $b; rebase first:\" >&2; echo \"  git rebase main && git land\" >&2; exit 1; fi; git -C \"$main_wt\" merge --ff-only \"$b\" || exit 1; echo \"landed $b on main; next: git push origin main\"; }; f";
      };

      core = {
        editor = "vim";
        pager = "delta";
        # Apple's ssh rather than the nixpkgs one ahead of it on PATH: only
        # Apple's reads key passphrases from the Keychain (UseKeychain), so a
        # key works without a prompt even when the agent is empty. Nix fetches
        # git+ssh flake inputs through git as well.
        sshCommand = "/usr/bin/ssh";
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
