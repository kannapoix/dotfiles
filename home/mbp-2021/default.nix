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
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    vim
    gh
    dig
    klog-time-tracker
    electrum
    btcdeb
  ];

  programs.home-manager.enable = true;
}
