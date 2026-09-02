{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        controlMaster = "auto";
        controlPath = "~/.ssh/master-%C";
        controlPersist = "10m";
      };
      "github.com" = {
        identityFile = "~/.ssh/id_ed25519_github";
        extraOptions = {
          UseKeychain = "yes";
          AddKeysToAgent = "yes";
        };
      };
    };
  };
}
