{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.zsh = {
    enable = true;
    setOptions = ["NONOMATCH"];
    # Prezto sets LESS only when it is empty; this is its default without -S (chop long lines).
    sessionVariables.LESS = "-g -i -M -R -w -X -z-4";
    prezto = {
      enable = true;
      pmodules = [
        "git"
        "environment"
        "terminal"
        "editor"
        "history"
        "directory"
        "spectrum"
        "utility"
        "completion"
        "history-substring-search"
        "prompt"
      ];

      extraConfig = ''
        zstyle ':prezto:*:*' color 'yes'
        zstyle ':prezto:module:editor' key-bindings 'emacs'
        zstyle ':prezto:module:prompt' theme 'sorin'
      '';
    };

    # After shellAliases (1100) so agent unaliases win over future aliases too.
    initContent = lib.mkOrder 1200 ''
      if [[ -n ''${CLAUDECODE:-} || -n ''${CURSOR_AGENT:-} ]]; then
        setopt CLOBBER
        unalias rm mv cp ln 2>/dev/null
      fi
    '';
  };
}
