{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.zsh = {
    enable = true;
    setOptions = ["NONOMATCH"];
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
  };
}
