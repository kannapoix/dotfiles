{
  config,
  lib,
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
    };
    permissions = {
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
      skills = lib.mapAttrs' (name: _: lib.nameValuePair name (../claude/skills + "/${name}")) (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../claude/skills)
      );
    };
  };
}
