{inputs, ...}: {
  flake = {
    darwinConfigurations."kBook-Pro" = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        ./mbp-2021/default.nix
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
