{
  config,
  pkgs,
  inputs,
  ...
}: {
  home.username = "uk";
  home.homeDirectory = "/Users/uk";

  # DONOT EDIT: https://nix-community.github.io/home-manager/index.xhtml#sec-upgrade-release-state-version
  home.stateVersion = "25.05"; # Please read the comment before changing.

  imports = [
    ../modules/git.nix
    ../modules/vscode.nix
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
  ];

  programs = {
    direnv.enable = true;
  };

  programs.home-manager.enable = true;
}
