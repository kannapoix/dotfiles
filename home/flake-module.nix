{inputs, ...}: {
  flake = {
    homeConfigurations."uk@kBook-Pro" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
      modules = [
        {
          nixpkgs.config.permittedInsecurePackages = [
            "python3.12-ecdsa-0.19.1"
          ];
        }
        ./mbp-2021/default.nix
      ];
      extraSpecialArgs = {inherit inputs;};
    };
  };
}
