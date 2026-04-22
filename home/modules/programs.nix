{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # direnv 2.36.0 pinned due to test failures in latest version.
  # Remove this pin once https://github.com/NixOS/nixpkgs/issues/507531 is resolved.
  pkgs-direnv = import inputs.nixpkgs-direnv {inherit (pkgs) system;};
in {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    package = pkgs-direnv.direnv;
  };

  programs.home-manager.enable = true;
}
