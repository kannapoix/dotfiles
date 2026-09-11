{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.claude;

  baseSettings = {
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
                if printf '%s' "$cmd" | grep -Eq 'git +push|home-manager +switch|darwin-rebuild +switch|run +nix-darwin'; then
                  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"git push and config-applying commands (home-manager/darwin-rebuild switch) always require explicit user approval"}}'
                fi
              '';
            }
          ];
        }
      ];
      # Auto-format edited Nix files in this repo with alejandra.
      PostToolUse = [
        {
          matcher = "Edit|Write|MultiEdit";
          hooks = [
            {
              type = "command";
              command = ''
                input=$(cat)
                remote=$(${pkgs.git}/bin/git config --get remote.origin.url 2>/dev/null || true)
                case "$remote" in
                  *kannapoix/dotfiles*) : ;;
                  *) exit 0 ;;
                esac
                file=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.tool_input.file_path // ""')
                case "$file" in
                  *.nix) : ;;
                  *) exit 0 ;;
                esac
                [ -f "$file" ] && ${pkgs.alejandra}/bin/alejandra --quiet "$file" >/dev/null 2>&1
                exit 0
              '';
            }
          ];
        }
      ];
      # Gate on the flake evaluating before finishing: mirrors the manual
      # `nix build` verify step, but cheap and cross-platform (eval only).
      Stop = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = ''
                input=$(cat)
                if [ "$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.stop_hook_active // false')" = "true" ]; then
                  exit 0
                fi
                remote=$(${pkgs.git}/bin/git config --get remote.origin.url 2>/dev/null || true)
                case "$remote" in
                  *kannapoix/dotfiles*) : ;;
                  *) exit 0 ;;
                esac
                root=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null) || exit 0
                cd "$root" || exit 0
                if ! out=$(${pkgs.nix}/bin/nix eval --extra-experimental-features 'nix-command flakes' --no-warn-dirty --json '.#homeConfigurations' --apply 'cs: builtins.mapAttrs (_: c: c.activationPackage.drvPath) cs' 2>&1); then
                  echo 'home-manager configs do not evaluate; fix before finishing:' >&2
                  printf '%s\n' "$out" >&2
                  exit 2
                fi
                if ! out=$(${pkgs.nix}/bin/nix eval --extra-experimental-features 'nix-command flakes' --no-warn-dirty --json '.#darwinConfigurations' --apply 'cs: builtins.mapAttrs (_: c: c.system.drvPath) cs' 2>&1); then
                  echo 'nix-darwin configs do not evaluate; fix before finishing:' >&2
                  printf '%s\n' "$out" >&2
                  exit 2
                fi
                exit 0
              '';
            }
          ];
        }
      ];
    };
    permissions = {
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
        "Bash(git push --force-with-lease:*)"
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
