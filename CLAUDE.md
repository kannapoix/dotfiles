# Working in this repo

- Sessions run in worktrees the desktop app creates, on `claude/*` branches. Commit there when asked, one commit per change; amending an unpushed commit is fine when that is the cleaner fix.
- Landing is the user's step: `git land` from the worktree fast-forwards main, then the user pushes. No pull requests and no merge commits; Claude never pushes.
- Verify a change with `nix build '.#homeConfigurations."uk@work-mac".activationPackage'` (the config named after this machine's hostname) and inspect `result/home-files/`, then remove `result`. Applying with `home-manager switch` or `darwin-rebuild switch` is the user's step.
