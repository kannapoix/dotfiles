{ ... }: {
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      font-family = "UDEV Gothic NF";
      keybind = [
        "shift+enter=text:\\n"
      ];
    };
  };
}
