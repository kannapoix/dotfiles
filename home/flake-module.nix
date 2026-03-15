{inputs, ...}: {
  flake = {
    homeConfigurations."uk@kBook-Pro" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.permittedInsecurePackages = [
            "python3.12-ecdsa-0.19.1"
          ];
        }
        ./mbp-2021/default.nix
      ];
      extraSpecialArgs = {inherit inputs;};
    };
    homeConfigurations."uk@kBook-Pro-24" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.permittedInsecurePackages = [
            "python3.12-ecdsa-0.19.1"
          ];
        }
        ./mbp-2024/default.nix
      ];
      extraSpecialArgs = {inherit inputs;};
    };
  };
}
