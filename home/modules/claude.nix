{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.claude;

  # Guarded edits of issue and PR bodies; the skills call it instead of gh edit.
  ghBodyEdit = pkgs.writers.writePython3Bin "gh-body-edit" {} (builtins.readFile ../claude/bin/gh-body-edit.py);

  # The variable Noto CJK face in nixpkgs registers only Thin, and resvg then
  # draws font-weight 400 and 700 as the same glyphs. Pin the JP face.
  notoSansCjkJp = let
    python = pkgs.python3.withPackages (ps: [ps.fonttools]);
  in
    pkgs.runCommand "noto-sans-cjk-jp" {nativeBuildInputs = [python];} ''
      mkdir -p "$out"
      python3 ${../claude/bin/instantiate-noto-cjk-jp.py} \
        ${pkgs.noto-fonts-cjk-sans}/share/fonts/opentype/noto-cjk/NotoSansCJK-VF.otf.ttc \
        "$out"
    '';

  # One opaque indexed PNG at the SVG's own pixel size, small enough to paste
  # into a GitHub body. White fills pixels the SVG leaves transparent. Quantizing
  # keeps at most 256 colors; dithering stays off so small text remains the
  # antialiased glyphs resvg drew.
  scopeDiagramPng = pkgs.writeShellScriptBin "scope-diagram-png" ''
    set -euo pipefail
    if [ "$#" -ne 2 ]; then
      echo "usage: scope-diagram-png input.svg output.png" >&2
      exit 2
    fi
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    ${pkgs.resvg}/bin/resvg \
      --skip-system-fonts \
      --languages ja \
      --use-fonts-dir ${notoSansCjkJp} \
      --background '#ffffff' \
      "$1" "$tmp/rgba.png"
    ${pkgs.pngquant}/bin/pngquant \
      --nofs \
      --force \
      --output "$2" \
      256 \
      "$tmp/rgba.png"
  '';

  # The skills that also work in a claude.ai chat, with no local shell, gh, or
  # dotfiles checkout behind them.
  claudeAiSkills = ["explain-diff" "grilling" "notion-writing" "one-by-one" "review-companion"];

  claudeAiSkillsTool = pkgs.writers.writePython3Bin "claude-ai-skills" {libraries = [pkgs.python3Packages.pyyaml];} (builtins.readFile ../claude/bin/claude-ai-skills.py);

  # A .skill per entry for the Claude desktop app to import, next to the
  # unzipped folder the check compares with claude.ai's copy.
  claudeAiSkillBundles = pkgs.runCommand "claude-ai-skills" {} ''
    ${claudeAiSkillsTool}/bin/claude-ai-skills pack ${../claude/skills} "$out" ${lib.escapeShellArgs claudeAiSkills}
  '';

  baseSettings = {
    attribution.commit = "";
    # The Bash tool otherwise runs the login shell (zsh here) with its profile
    # snapshotted in, so bash scripts trip over zsh's parsing, word splitting,
    # and the path array. The override is read by the CLI and the desktop app
    # (undocumented as of 2.1.273); with no bash rc file the snapshot holds only
    # Claude Code's own defaults and the same PATH as before.
    env.CLAUDE_CODE_SHELL = "${pkgs.bashInteractive}/bin/bash";
    hooks = {
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
              # Permission rules match only the plain spelling, so this also
              # catches `git -C dir push`, options before a rebuild subcommand,
              # and running a built generation's activate script directly. Each
              # rule adds its own reason, so a prompt names only what matched.
              command = ''
                cmd=$(${pkgs.jq}/bin/jq -r '.tool_input.command // ""')
                has() { printf '%s' "$cmd" | ${pkgs.gnugrep}/bin/grep -Eq "$@"; }
                decide() {
                  ${pkgs.jq}/bin/jq -nc --arg d "$1" --arg r "$2" \
                    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
                }

                if has 'gh +pr +(ready|merge)'; then
                  decide deny "gh pr ready and gh pr merge are always run by the user; report that the PR is ready and stop"
                  exit 0
                fi

                reason=""
                add() { if [ -n "$reason" ]; then reason="$reason; $1"; else reason=$1; fi; }
                has '(^|[^[:alnum:]_-])git( +-[cC] +[^ ]+| +--?[[:alnum:]-]+(=[^ ]+)?)* +push([^[:alnum:]_]|$)' \
                  && add "git push: approve only if you asked for this push"
                has -e '(^|[^[:alnum:]_-])(home-manager|darwin-rebuild|nixos-rebuild)( +[^ ;&|]+)* +(switch|boot|test|activate|uninstall)([^[:alnum:]_-]|$)' -e 'run +nix-darwin' \
                  && add "config apply (home-manager, darwin-rebuild, nixos-rebuild): approve only if you asked to apply it"
                has '(result[^ /;&|]*|/nix/store/[^ /;&|]+)/activate(-user)?([^[:alnum:]_.-]|$)' \
                  && add "activate script: running a built generation's activate applies that configuration; approve only if you asked to apply it"
                if [ -n "$reason" ]; then
                  decide ask "$reason"
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

  options.modules.claude.claudeAiSkillsCheck = lib.mkEnableOption "the launchd agent that asks to upload skills claude.ai is missing or behind on";

  config = {
    home.sessionPath = ["$HOME/.local/bin"];
    home.packages = [ghBodyEdit scopeDiagramPng claudeAiSkillsTool];
    home.file.".local/share/claude-ai-skills".source = claudeAiSkillBundles;

    # claude.ai has no upload API, so the upload is left to the user: the
    # check asks to open whatever claude.ai is missing or behind on. The bundle
    # path changes with the skills, so a switch that changes one reloads the
    # agent and RunAtLoad asks right away; the daily run is the reminder.
    launchd.agents.claude-ai-skills = {
      enable = cfg.claudeAiSkillsCheck;
      config = {
        ProgramArguments = ["${claudeAiSkillsTool}/bin/claude-ai-skills" "check" "${claudeAiSkillBundles}"];
        RunAtLoad = true;
        StartCalendarInterval = [
          {
            Hour = 10;
            Minute = 0;
          }
        ];
      };
    };

    programs.claude-code = {
      enable = true;
      package = null;
      settings = lib.recursiveUpdate baseSettings cfg.settings;
      context = ../claude/CLAUDE.md;
      agentsDir = ../claude/agents;
      skills = lib.mapAttrs' (name: _: lib.nameValuePair name (../claude/skills + "/${name}")) (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../claude/skills)
      );
    };
  };
}
