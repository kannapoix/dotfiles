{inputs, ...}: {
  flake = {
    darwinConfigurations."kBook-Pro" = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        ./mbp-2021/default.nix
      ];
      specialArgs = {inherit inputs;};
    };
    darwinConfigurations."kBook-Pro-24" = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        ./mbp-2024/default.nix
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
