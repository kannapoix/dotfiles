{inputs, ...}: {
  flake = {
    homeConfigurations."uk@kBook-Pro" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
        overlays = [inputs.nur.overlays.default];
      };
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
    homeConfigurations."uk@work-mac" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
        overlays = [inputs.nur.overlays.default];
      };
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.permittedInsecurePackages = [
            "python3.12-ecdsa-0.19.1"
          ];
        }
        ./work-mac/default.nix
      ];
      extraSpecialArgs = {inherit inputs;};
    };
  };
}
