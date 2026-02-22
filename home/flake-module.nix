{inputs, ...}: {
  flake = {
    homeConfigurations."uk@kBook-Pro" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
      modules = [
        ./mbp-2021/default.nix
      ];
      extraSpecialArgs = {inherit inputs;};
    };
  };
}
