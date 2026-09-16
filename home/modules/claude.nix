{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.claude;

  # Guarded edits of issue and PR bodies; the skills call it instead of gh edit.
  ghBodyEdit = pkgs.writers.writePython3Bin "gh-body-edit" {} (builtins.readFile ../claude/bin/gh-body-edit.py);

  baseSettings = {
    attribution.commit = "";
    hooks = {
      Notification = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'";
            }
          ];
        }
      ];
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = ''
                cmd=$(${pkgs.jq}/bin/jq -r '.tool_input.command // ""')
                if printf '%s' "$cmd" | grep -q 'gh pr create' \
                   && ! printf '%s' "$cmd" | grep -q -- '--draft'; then
                  echo 'PRs must be created as drafts. Re-run with: gh pr create --draft' >&2
                  exit 2
                fi
              '';
            }
            {
              type = "command";
              command = ''
                cmd=$(${pkgs.jq}/bin/jq -r '.tool_input.command // ""')
                if printf '%s' "$cmd" | grep -Eq 'gh +pr +(ready|merge)'; then
                  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"gh pr ready and gh pr merge are always run by the user; report that the PR is ready and stop"}}'
                elif printf '%s' "$cmd" | grep -Eq 'git +push|home-manager +switch|darwin-rebuild +switch|run +nix-darwin'; then
                  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"git push and config-applying commands (home-manager/darwin-rebuild switch) always require explicit user approval"}}'
                fi
              '';
            }
          ];
        }
      ];
    };
    permissions = {
      deny = [
        "Bash(gh pr ready:*)"
        "Bash(gh pr merge:*)"
      ];
      ask = [
        "Bash(git push:*)"
        "Bash(home-manager switch:*)"
        "Bash(darwin-rebuild switch:*)"
        "Bash(sudo darwin-rebuild switch:*)"
      ];
      allow = [
        "Bash(gh pr view:*)"
        "Bash(gh pr list:*)"
        "Bash(gh pr diff:*)"
        "Bash(gh pr checks:*)"
        "Bash(gh pr status:*)"
        "Bash(gh issue view:*)"
        "Bash(gh issue list:*)"
        "Bash(gh run list:*)"
        "Bash(gh run view:*)"
        "Bash(gh workflow list:*)"
        "Bash(gh workflow view:*)"
        "Bash(gh repo view:*)"
        "Bash(gh release list:*)"
        "Bash(gh release view:*)"
        "Bash(gh search:*)"
        "Bash(gh auth status)"
        "Bash(gh pr checkout:*)"
        "Bash(git fetch:*)"
        "Bash(git rebase:*)"
        "Bash(git symbolic-ref:*)"
        "Bash(git remote show:*)"
        "Bash(git rev-parse:*)"
        "Bash(git merge-base:*)"
        "Bash(git status:*)"
      ];
    };
  };
in {
  options.modules.claude.settings = lib.mkOption {
    type = lib.types.attrs;
    default = {};
    description = "Host-specific Claude Code settings, deep-merged into the base settings.";
  };

  config = {
    home.sessionPath = ["$HOME/.local/bin"];
    home.packages = [ghBodyEdit];

    programs.claude-code = {
      enable = true;
      package = null;
      settings = lib.recursiveUpdate baseSettings cfg.settings;
      memory.source = ../claude/CLAUDE.md;
      skills = lib.mapAttrs' (name: _: lib.nameValuePair name (../claude/skills + "/${name}")) (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../claude/skills)
      );
    };
  };
}
