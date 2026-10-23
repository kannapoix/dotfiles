{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "Match all" = lib.hm.dag.entryBefore ["github.com" "i-* mi-*"] {
        IgnoreUnknown = "UseKeychain";
      };
      "github.com" = {
        IdentityFile = "~/.ssh/id_ed25519_github";
        UseKeychain = "yes";
        AddKeysToAgent = "yes";
      };
    };
  };
}
