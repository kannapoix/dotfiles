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
            nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake "${self}#$HOSTNAME"
          '');
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
