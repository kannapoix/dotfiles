{inputs, ...}: {
  flake = {
    darwinConfigurations."kBook-Pro" = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        {
          nixpkgs.config.permittedInsecurePackages = [
            "python3.12-ecdsa-0.19.1"
          ];
        }
        ./mbp-2021/default.nix
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
