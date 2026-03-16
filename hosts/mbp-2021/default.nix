{
  config,
  pkgs,
  inputs,
  ...
}: {
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    home-manager
  ];

  nix.settings.experimental-features = "nix-command flakes";

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
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
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    config.boot.binfmt.emulatedSystems = ["x86_64-linux"];
  };
  # Required by linux-builder
  nix.settings.trusted-users = ["@admin"];

  system.primaryUser = "uk";

  system.defaults = {
    dock = {
      autohide = true;
      expose-group-apps = true;
    };
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
    };
    CustomUserPreferences = {
      NSGlobalDomain = {
        "com.apple.mouse.scaling" = 3;
        "com.apple.trackpad.scaling" = 0.875;
      };
    };
  };
}
