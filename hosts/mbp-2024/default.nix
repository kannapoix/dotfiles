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

  system.primaryUser = "uk";

  fonts.packages = with pkgs; [
    udev-gothic-nf
  ];

  homebrew = {
    enable = true;
    casks = [
      "dbeaver-community"
      "firefox"
      "claude"
      "ghostty"
      "notion"
      "visual-studio-code"
      "session-manager-plugin"
    ];
    onActivation.cleanup = "zap";
  };

  system.defaults = {
    dock = {
      autohide = true;
      expose-group-apps = true;
      persistent-apps = [
        "/System/Applications/Utilities/Activity Monitor.app"
      ];
      wvous-tl-corner = 14; # Quick Note
      wvous-tr-corner = 12; # Notification Center
      wvous-bl-corner = 13; # Lock Screen
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
