{ pkgs, ... }: {
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    settings = {
      font-family = "UDEV Gothic NF";
      keybind = [
        "shift+enter=text:\\n"
      ];
    };
  };
}
