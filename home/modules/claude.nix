{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.modules.claude;

  dirNames = dir: lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir));
  pstackPrinciples = builtins.filter (lib.hasPrefix "principle-") (dirNames "${inputs.cursor-plugins}/pstack/skills");
  ownPrinciplesDir = ../claude/principles;
  ownPrinciples =
    if builtins.pathExists ownPrinciplesDir
    then dirNames ownPrinciplesDir
    else [];
  # builtins.split puts each match's capture groups in a list between the
  # unmatched strings.
  heyIndexed = lib.sort lib.lessThan (lib.unique (lib.flatten (
    builtins.filter builtins.isList (builtins.split "`(principle-[a-z0-9-]+)`" (builtins.readFile ../claude/skills/hey/SKILL.md))
  )));

  # Guarded edits of issue, PR, and comment bodies; the skills call it instead
  # of gh edit and gh api PATCH.
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
  claudeAiSkills = ["explain-diff" "grilling" "japanese-writing" "notion-writing" "one-by-one" "review-companion"];

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
              # One pull request per session (global CLAUDE.md). Only the
              # transcript lines this session wrote count: a fork keeps its
              # parent's lines under the parent's sessionId, and the session a
              # PR is handed to may start as a fork. A merged or closed PR has
              # no writer left to clash with; when gh cannot tell, the PR
              # counts as open.
              command = ''
                input=$(cat)
                n=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r \
                  '[.tool_input.command // "" | scan("(?:^|[^[:alnum:]_-])gh +pr +create(?![[:alnum:]_-])")] | length')
                case "$n" in
                  "" | 0) exit 0 ;;
                  1) ;;
                  *)
                    echo "This command opens $n pull requests. One session holds one PR, so that only its own review handling and Auto-fix write to it: open this session's PR alone, and hand each other PR to a session of its own (in the desktop app, start_session, or hand_off_to_session for the task in flight, naming the branch and what the PR is for; elsewhere, tell the user which PRs are left to open)." >&2
                    exit 2
                    ;;
                esac
                sid=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.session_id // ""')
                transcript=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.transcript_path // ""')
                [ -n "$sid" ] && [ -r "$transcript" ] || exit 0
                open=""
                for url in $(${pkgs.jq}/bin/jq -Rrn --arg s "$sid" '
                  reduce (inputs | fromjson? | objects | select(.sessionId == $s)
                          | .message.content? | arrays | .[] | objects) as $c
                    ({ids: {}, urls: []};
                     if $c.type == "tool_use" and $c.name == "Bash" and ($c.input.command? // "" | tostring | test("gh +pr +create"))
                     then .ids[$c.id] = true
                     elif $c.type == "tool_result" and .ids[$c.tool_use_id // ""]
                     then .urls += [$c.content | tostring | scan("https://github\\.com/[^/\\s\"]+/[^/\\s\"]+/pull/[0-9]+")]
                     else . end)
                  | .urls | unique | .[]' "$transcript"); do
                  state=$(${pkgs.coreutils}/bin/timeout 15 ${pkgs.gh}/bin/gh pr view "$url" --json state --jq .state 2>/dev/null) || state=""
                  case "$state" in MERGED|CLOSED) ;; *) open="$open $url" ;; esac
                done
                if [ -n "$open" ]; then
                  echo "This session already opened$open, and it is not merged or closed. One session holds one PR, so that only its own review handling and Auto-fix write to it: hand this PR to a session of its own (in the desktop app, start_session, or hand_off_to_session for the task in flight, naming the branch and what the PR is for; elsewhere, tell the user which PR is left to open). If this PR replaces that one, ask the user to close that one first." >&2
                  exit 2
                fi
              '';
            }
            {
              type = "command";
              # Sessions started side by side can share one worktree, and the
              # rule above cannot stop two of them holding one branch: the
              # app's PR bindings are not visible to a hook. So a command that
              # rewrites or publishes the branch asks first when another
              # session wrote a transcript line in this worktree in the last
              # 10 minutes. Sessions that start in one folder keep their
              # transcripts in one directory; a line's own timestamp decides,
              # since the app touches idle transcripts' mtimes in bulk.
              command = ''
                input=$(cat)
                cmd=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.tool_input.command // ""')
                printf '%s' "$cmd" | ${pkgs.gnugrep}/bin/grep -Eq \
                  -e '(^|[^[:alnum:]_-])git( +-[cC] +[^ ]+| +--?[[:alnum:]-]+(=[^ ]+)?)* +(push|rebase|rb|squash-fixups)([^[:alnum:]_-]|$)' \
                  -e '(^|[^[:alnum:]_-])git( +-[cC] +[^ ]+| +--?[[:alnum:]-]+(=[^ ]+)?)* +commit([^;&|]* )?--amend' \
                  || exit 0
                sid=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.session_id // ""')
                cwd=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.cwd // ""')
                transcript=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.transcript_path // ""')
                [ -n "$sid" ] && [ -n "$cwd" ] && [ -r "$transcript" ] || exit 0
                root=$(${pkgs.git}/bin/git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || root=$cwd
                now=$(${pkgs.coreutils}/bin/date -u +%s)
                others=""
                for f in $(${pkgs.findutils}/bin/find "$(${pkgs.coreutils}/bin/dirname "$transcript")" -maxdepth 1 -name '*.jsonl' -mmin -10 ! -name "$sid.jsonl"); do
                  other=$(${pkgs.coreutils}/bin/tail -n 50 "$f" | ${pkgs.jq}/bin/jq -Rrn --arg root "$root" --argjson now "$now" '
                    [inputs | fromjson? | objects | select(.timestamp and .cwd and .sessionId)] | last // empty
                    | select((.cwd == $root or (.cwd | startswith($root + "/")))
                             and ($now - (.timestamp | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)) < 600)
                    | .sessionId')
                  [ -n "$other" ] && others="$others $other"
                done
                [ -n "$others" ] || exit 0
                ${pkgs.jq}/bin/jq -nc --arg r "Another session wrote in this worktree in the last 10 minutes ($others ). Two sessions rewriting one branch in one folder overwrite each other's work: approve only if this session is the one that owns this branch and its PR." \
                  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
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
            {
              type = "command";
              # The shell side of the Read deny on the AWS credential caches,
              # plus an SSO token handed to aws on the command line (only the
              # aws sso subcommands take --access-token). A string match, so a
              # path built up in pieces still gets through.
              command = ''
                cmd=$(${pkgs.jq}/bin/jq -r '.tool_input.command // ""')
                if printf '%s' "$cmd" | ${pkgs.gnugrep}/bin/grep -Eq \
                     -e '\.aws/(sso|cli)/cache' \
                     -e '(^|[^[:alnum:]_-])aws [^;&|]*--access-token'; then
                  echo 'Do not read the AWS credential caches (~/.aws/sso/cache, ~/.aws/cli/cache) or pass an SSO access token to aws. To find accounts or roles, or when an SSO login is needed, ask the user to run aws configure sso or aws sso login.' >&2
                  exit 2
                fi
              '';
            }
            {
              type = "command";
              # A glob in the first component under /nix/store, or find, ls,
              # grep and the like given the store root, walks every path nix
              # has built and does not return in time. A concrete
              # /nix/store/<hash>-<name>/... path stays allowed.
              command = ''
                cmd=$(${pkgs.jq}/bin/jq -r '.tool_input.command // ""')
                if printf '%s' "$cmd" | ${pkgs.gnugrep}/bin/grep -Eq \
                     -e '(^|[[:space:]=])/nix/store/[^/[:space:]]*[*?]' \
                     -e '(^|[;&|(]|[[:space:]])(find|fd|ls|du|tree|rg|grep)[[:space:]]([^;&|]*[[:space:]])?/nix/store/?([[:space:];&|)]|$)'; then
                  echo 'Do not glob or search across /nix/store; it does not return in time. Ask nix for the path instead: nix eval --raw nixpkgs#<pkg>.outPath, nix build --no-link --print-out-paths <installable>, or nix path-info <installable>. A concrete /nix/store/<hash>-<name>/... path is fine.' >&2
                  exit 2
                fi
              '';
            }
            {
              type = "command";
              # git replay updates refs itself unless --ref-action=print is
              # given (the default is update as of git 2.54), including
              # branches another worktree has checked out. Each git replay in
              # the command is checked on its own.
              command = ''
                cmd=$(${pkgs.jq}/bin/jq -r '.tool_input.command // ""')
                runs=$(printf '%s' "$cmd" | ${pkgs.gnugrep}/bin/grep -Eo \
                  '(^|[^[:alnum:]_-])git( +-[cC] +[^ ]+| +--?[[:alnum:]-]+(=[^ ]+)?)* +replay([[:space:]][^;&|]*)?')
                if [ -n "$runs" ] && printf '%s\n' "$runs" \
                     | ${pkgs.gnugrep}/bin/grep -Ev -e '--ref-action(=| +)print' -e ' (-h|--help)( |$)' \
                     | ${pkgs.gnugrep}/bin/grep -q .; then
                  echo 'Run git replay only with --ref-action=print: without it, git replay moves the refs itself. Read the printed update-ref lines, and move a branch with a command the user can follow, such as git rebase.' >&2
                  exit 2
                fi
              '';
            }
            {
              type = "command";
              # In `cd dir; rest` or a cd on a line of its own, a cd that fails
              # (a scratchpad subdirectory cleared on restart, say) leaves rest
              # running in the old directory, where it writes into the
              # worktree. `cd dir || exit; rest` and `if cd dir; then` do not
              # match, and a command that turns on `set -e` passes.
              command = ''
                cmd=$(${pkgs.jq}/bin/jq -r '.tool_input.command // ""')
                if printf '%s' "$cmd" | ${pkgs.jq}/bin/jq -Rse '
                     test("(^|[;&|(\\n])[[:blank:]]*cd([[:blank:]]+[^;&|\\n]*)?[[:blank:]]*(;|\\n[[:blank:]]*[^[:space:]])")
                     and (test("(^|[;&|\\n])[[:blank:]]*set[[:blank:]]+-[a-z]*e") | not)' >/dev/null; then
                  echo 'cd is followed by ; or a new line, so when cd fails the rest still runs in the old directory. Join it with && (with mkdir -p first when the directory may not exist), or use absolute paths.' >&2
                  exit 2
                fi
              '';
            }
          ];
        }
      ];
      Stop = [
        {
          hooks = [
            {
              type = "command";
              # The reply-language line in CLAUDE.md kept failing, most often in
              # the closing text after a tool call whose output is English. When
              # the user's latest message is Japanese (3 in 10 letters or more
              # kana or kanji) and the last reply has under 1 in 10, both
              # counted without code, URLs, and tags, the reply goes back once.
              # Only messages the user typed count (origin human). A message
              # with no words of its own, such as a slash command with a URL,
              # keeps the earlier message's language, and Japanese when there
              # is none. A transcript with no typed message, as from claude -p,
              # is left alone.
              command = ''
                input=$(cat)
                [ "$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.stop_hook_active // false')" = true ] && exit 0
                transcript=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.transcript_path // ""')
                [ -r "$transcript" ] || exit 0
                ${pkgs.coreutils}/bin/tail -n 2000 "$transcript" | ${pkgs.jq}/bin/jq -Rrn '
                  def text: if type == "string" then . else (map(select(.type? == "text") | .text) | join("\n")) end;
                  def prose: gsub("(?s)<system-reminder>.*?</system-reminder>|<command-[a-z]+>.*?</command-[a-z]+>|```.*?```|`[^`\n]*`|https?://[^\\s)>\\]]+"; " ");
                  def cjk: [scan("[\\p{Han}\\p{Hiragana}\\p{Katakana}]")] | length;
                  def letters: [scan("\\p{L}")] | length;
                  reduce (inputs | fromjson? | objects) as $l ({seen: false, user: null, reply: null};
                    if $l.type == "user" and $l.origin.kind? == "human" then
                      ($l.message.content | text | prose) as $t
                      | .seen = true | .reply = null
                      | if ($t | letters) > 0 then .user = $t else . end
                    elif $l.type == "assistant" then
                      ($l.message.content | if type == "array" then map(select(.type == "text") | .text) | join("\n") else "" end) as $t
                      | if ($t | length) > 0 then .reply = $t else . end
                    else . end)
                  | select(.seen and .reply != null)
                  | (.user // "日本語" | [cjk, letters]) as [$uc, $ul]
                  | (.reply | prose | [cjk, letters]) as [$rc, $rl]
                  | select($uc * 10 >= $ul * 3 and $rl >= 40 and $rc * 10 < $rl)
                  | {decision: "block", reason: "The last reply is not in Japanese, the language of the latest message from the user. Write it again in Japanese, keeping code, identifiers, commands, and quotations as they are, and call no tool for it."}'
              '';
            }
          ];
        }
      ];
    };
    permissions = {
      # Bash is not covered, and CLIs before 2.1.314 ignore the key. From
      # another project's session, `/add-dir ~/dotfiles` lets the file tools
      # edit this repo again.
      blockWritesOutsideWorkingDirectories = true;
      deny = [
        "Bash(gh pr ready:*)"
        "Bash(gh pr merge:*)"
        # SSO access tokens and the role credentials made from them. Bash reads
        # of the same paths go through the PreToolUse hook instead.
        "Read(~/.aws/sso/cache/**)"
        "Read(~/.aws/cli/cache/**)"
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
        # The entry skill, which verifier reads first, and the principle
        # bodies it sends Claude to read.
        "Read(~/.claude/skills/hey/**)"
        "Read(~/.claude/pstack/**)"
        "Read(~/.claude/principles/**)"
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
    # GNU coreutils and a current python3, ahead of macOS's /usr/bin in the
    # Bash tool's PATH (and the login shell's): Claude writes GNU forms such as
    # `head -c -1` and `timeout`, and /usr/bin/python3 (3.9) rejects a long
    # line holding multibyte text unless the script declares its encoding.
    home.packages = [ghBodyEdit scopeDiagramPng claudeAiSkillsTool pkgs.coreutils pkgs.python3];
    home.file =
      {
        ".local/share/claude-ai-skills".source = claudeAiSkillBundles;
        # The whole pstack folder rather than the principle-* skills alone:
        # two principles link to sibling pstack skills, and the folder carries
        # the LICENSE. Like ~/.claude/principles, it sits outside
        # ~/.claude/skills, so none of it loads on its own.
        ".claude/pstack".source = "${inputs.cursor-plugins}/pstack";
      }
      // lib.listToAttrs (map (name: lib.nameValuePair ".claude/principles/${name}" {source = ownPrinciplesDir + "/${name}";}) ownPrinciples);

    # The hey skill's indexes are written by hand, so a pstack bump that adds,
    # drops, or renames a principle, or an own principle missing from the
    # index, fails the build instead of leaving an entry that points nowhere.
    assertions = [
      {
        assertion = heyIndexed == lib.sort lib.lessThan (pstackPrinciples ++ ownPrinciples);
        message = ''
          The principle names in backticks in home/claude/skills/hey/SKILL.md must match the installed principles.
            indexed:   ${toString heyIndexed}
            installed: ${toString (lib.sort lib.lessThan (pstackPrinciples ++ ownPrinciples))}
        '';
      }
    ];

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
