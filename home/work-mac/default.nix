{
  config,
  pkgs,
  inputs,
  ...
}: {
  home.username = "uk";
  home.homeDirectory = "/Users/uk";

  # DONOT EDIT: https://nix-community.github.io/home-manager/index.xhtml#sec-upgrade-release-state-version
  home.stateVersion = "25.11"; # Please read the comment before changing.

  imports = [
    ../modules/git.nix
    ../modules/zsh.nix
    ../modules/programs.nix
    ../modules/firefox.nix
    ../modules/ssh.nix
    ../modules/ghostty.nix
    ../modules/claude.nix
  ];

  modules.firefox.syncDeviceName = "work-mac";

  modules.claude.settings.enabledPlugins = {
    "aikido@claude-plugins-official" = true;
  };
  modules.claude.claudeAiSkillsCheck = true;

  home.packages = with pkgs; [
    vim
    gh
    dig
    klog-time-tracker
    btcdeb
    delta
    jq
    nil
    alejandra
    gnused
    awscli2
    openssh
  ];

  programs.ssh.settings = {
    "i-* mi-*" = {
      ProxyCommand = "sh -c \"aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'\"";
      IdentityAgent = "~/.ssh/agent.sock";
      AddKeysToAgent = "yes";
    };
  };

  # FIDO-capable ssh-agent for sk keys. Apple's agent cannot sign with them.
  launchd.agents.ssh-agent = {
    enable = true;
    config = {
      ProgramArguments = [
        (toString (pkgs.writeShellScript "ssh-agent-fido" ''
          sock="$HOME/.ssh/agent.sock"
          rm -f "$sock"
          exec ${pkgs.openssh}/bin/ssh-agent -D -a "$sock"
        ''))
      ];
      KeepAlive = true;
      RunAtLoad = true;
    };
  };
}
