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
      "ignore-unknown" = lib.hm.dag.entryBefore ["github.com" "i-* mi-*"] {
        match = "all";
        extraOptions.IgnoreUnknown = "UseKeychain";
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
