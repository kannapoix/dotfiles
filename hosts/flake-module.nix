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
        inputs.nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "uk";
            taps = {
              "homebrew/homebrew-core" = inputs.homebrew-core;
              "homebrew/homebrew-cask" = inputs.homebrew-cask;
            };
            mutableTaps = false;
          };
        }
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
