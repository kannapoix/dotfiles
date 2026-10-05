{pkgs, ...}: {
  # Cursor Desktop has no declarative equivalent of Claude Code's
  # permissions.ask. Gate pushes with a user-level shell hook instead.
  home.file.".cursor/hooks.json".text = builtins.toJSON {
    version = 1;
    hooks.beforeShellExecution = [
      {
        matcher = ''(^|[;&|]\s*)git(?:\s+-C\s+\S+)*\s+push(?:\s|$)'';
        command = "${pkgs.jq}/bin/jq -nc '{permission:\"ask\",user_message:\"git push requires explicit approval.\",agent_message:\"Run git push only when the current user message explicitly requested it.\"}'";
        failClosed = true;
      }
    ];
  };
}
