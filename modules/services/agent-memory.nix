{
  config,
  lib,
  pkgs,
  primaryUser ? null,
  repoRoot ? null,
  ...
}:

let
  iiiEngine = pkgs.callPackage ../../pkgs/iii-engine.nix { };
  enabled = repoRoot != null && primaryUser != null;
  agentMemoryHome = config.users.users.${primaryUser}.home or "/home/${primaryUser}";
in
{
  config = lib.mkIf enabled {
    systemd.services.agentmemory = {
      description = "agentmemory.dev persistent agent memory server";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.bash}/bin/bash ${repoRoot}/resources/agent-memory/start.sh";
        EnvironmentFile = "${repoRoot}/resources/agent-memory/config.env";
        WorkingDirectory = repoRoot;
        User = primaryUser;
        StateDirectory = "agentmemory";
        StateDirectoryMode = "0700";
        Environment = [
          "HOME=${agentMemoryHome}"
          "PATH=${pkgs.nodejs_22}/bin:${iiiEngine}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin"
        ];
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        UMask = "0077";
      };
    };
  };
}
