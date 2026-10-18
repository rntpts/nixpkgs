{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.lk-jwt-service;

  credentials = lib.mapAttrsToList (name: value: "${name}:${value}") cfg.credentials;
  credentialsEnv = lib.mapAttrs (name: _: "%d/${name}") cfg.credentials;
in
{
  meta.maintainers = [ lib.maintainers.quadradical ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "lk-jwt-service" "port" ]
      [ "services" "lk-jwt-service" "environment" "LIVEKIT_JWT_PORT" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "lk-jwt-service" "keyFile" ]
      [ "services" "lk-jwt-service" "environment" "LIVEKIT_KEY_FILE" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "lk-jwt-service" "livekitUrl" ]
      [ "services" "lk-jwt-service" "environment" "LIVEKIT_URL" ]
    )
  ];

  options.services.lk-jwt-service = {
    enable = lib.mkEnableOption "lk-jwt-service";

    package = lib.mkPackageOption pkgs "lk-jwt-service" { };

    environment = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf lib.types.str;
      };
      default = { };
      description = ''
        Environment variables for configuring lk-jwt-service.
        This field will end up public in /nix/store, for secret values (such as `LIVEKIT_KEY` and `LIVEKIT_SECRET`). Use the `_FILE` versions and pass them with `credentials` or use `environmentFile`.

        See <https://github.com/element-hq/lk-jwt-service#%EF%B8%8F-configuration> for available options.
      '';
    };

    credentials = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf lib.types.str;
      };
      default = { };
      description = ''
        Environment variables for configuring lk-jwt-service.
        The values here will be interpreted as systemd credentials and passed through LoadCredential.

        See <https://github.com/element-hq/lk-jwt-service#%EF%B8%8F-configuration> for available options.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr (lib.types.pathWith { inStore = false; });
      default = null;
      example = "/run/secrets/lk-jwt-service.env";
      description = ''
        Path to an environment file for lk-jwt-service.

        Use this file to supply secret configuration such as `LIVEKIT_KEY`
        and `LIVEKIT_SECRET`. The file must contain lines in the form
        `KEY=value` and should be managed by a secret store such as
        sops-nix or agenix, so that its contents do not end up in the
        Nix store.

        See <https://github.com/element-hq/lk-jwt-service#%EF%B8%8F-configuration>
        for available variables.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.lk-jwt-service = {
      description = "Minimal service to issue LiveKit JWTs for MatrixRTC";
      documentation = [ "https://github.com/element-hq/lk-jwt-service" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      environment = cfg.environment // credentialsEnv;

      serviceConfig = {
        EnvironmentFile = cfg.environmentFile;
        LoadCredential = credentials;
        ExecStart = lib.getExe cfg.package;
        DynamicUser = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateUsers = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        ProtectHome = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@resources"
        ];
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "077";
      };
    };

    warnings = lib.optional (cfg.environment ? LIVEKIT_JWT_PORT) ''
      `services.lk-jwt-service.environment.LIVEKIT_JWT_PORT` is set, but this environment variable is deprecated upstream.

      Use `services.lk-jwt-service.environment.LIVEKIT_JWT_BIND` instead.
    '';
  };
}
