{
  config,
  pkgs,
  inputs,
  ...
}: {
  home.username = "uk";
  home.homeDirectory = "/Users/uk";

  # DONOT EDIT: https://nix-community.github.io/home-manager/index.xhtml#sec-upgrade-release-state-version
  home.stateVersion = "25.11"; # Please read the comment before changing.

  imports = [
    ../modules/git.nix
    ../modules/zsh.nix
    ../modules/programs.nix
    ../modules/firefox.nix
    ../modules/ssh.nix
    ../modules/ghostty.nix
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
    nil
    alejandra
    gnused
    awscli2
  ];

  programs.ssh.matchBlocks = {
    "i-* mi-*" = {
      proxyCommand = "sh -c \"aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'\"";
    };
  };
}
