{
  config,
  pkgs,
  inputs,
  ...
}: {
  home.username = "uk";
  home.homeDirectory = "/Users/uk";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.

  # DONOT EDIT: https://nix-community.github.io/home-manager/index.xhtml#sec-upgrade-release-state-version
  home.stateVersion = "25.05"; # Please read the comment before changing.

  imports = [
    ../modules/git.nix
  ];

  home.packages = with pkgs; [
    vim
    gh
    dig
    klog-time-tracker
    electrum
    btcdeb
    delta
    jq
    slack
  ];

  programs = {
    direnv.enable = true;
  };

  programs.home-manager.enable = true;
}
