{
  outputs = {
    flake-parts,
    self,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./hosts/flake-module.nix
        ./home/flake-module.nix
      ];
      systems = ["aarch64-darwin"];

      perSystem = {pkgs, ...}: {
        apps.default = {
          type = "app";
          program = toString (pkgs.writeShellScript "install" ''
            set -euo pipefail
            HOSTNAME=''${1:-$(hostname -s)}
            sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake "${self}#$HOSTNAME"
            if [ ! -d "$HOME/dotfiles" ]; then
              ${pkgs.git}/bin/git clone https://github.com/kannapoix/dotfiles.git "$HOME/dotfiles"
            fi
          '');
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    nixpkgs-direnv.url = "github:NixOS/nixpkgs/5b5b46259bef947314345ab3f702c56b7788cab8";
};
}
