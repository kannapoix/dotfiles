{
  config,
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    home-manager
  ];

  nix.settings.experimental-features = "nix-command flakes";

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.linux-builder = {
    enable = true;
    ephemeral = true;
    maxJobs = 6;
    config = {
      virtualisation = {
        darwin-builder = {
          diskSize = 40 * 1024;
          memorySize = 8 * 1024;
        };
        cores = 6;
      };
    };
    # systems = [
    #   "x86_64-linux"
    #   "aarch64-linux"
    # ];
    # config.boot.binfmt.emulatedSystems = ["x86_64-linux"];
  };
  nix.settings.trusted-users = ["@admin"];
}
