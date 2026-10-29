# Working in this repo

This repository is public, and it is worked on from several machines, each signed in to its own Claude account with its own auto memory.

## How work lands

- Sessions run in worktrees the desktop app creates, on `claude/*` branches. Commit there when the user asks, one commit per change; amending an unpushed commit is fine when that is the cleaner fix.
- The user lands a branch with `git land` from the worktree, which fast-forwards main, then pushes it and applies the configuration on each machine.
- Verify a change with `nix flake check`, which builds every host's configuration. To inspect the generated files, build this machine's home configuration with `nix build ".#homeConfigurations.\"uk@$(hostname -s)\".activationPackage"`, read `result/home-files/`, then remove `result`.

## Writing skills and CLAUDE.md files

- Write skills in English, whatever language the session uses; trigger phrases in `description` and fixed output strings may be in another language.
- Put what the agent must not do in one list of `Do not …` bullets, so a reviewer can check them at a glance.

## Rules while working here

- Do not push.
- Do not open pull requests or create merge commits.
- Do not run `home-manager switch`, `darwin-rebuild switch`, a generation's `activate` script, or anything else that applies a configuration.
- Do not commit before the user asks.
- Do not put a work project's names, host names, or key filenames, issue numbers, or quotations from another project or a session in committed text or commit messages.
- Do not keep a rule for this repo only in auto memory; put it here, or in `home/claude/CLAUDE.md` when it holds for every project.
- Do not write a skill or a permission allowlist entry for a mechanical git workflow; propose an alias in `home/modules/git.nix` for the user to run.
- Do not give the skills in `claudeAiSkills` (`home/modules/claude.nix`) commands or local paths: they also run in claude.ai chats with no shell behind them.
