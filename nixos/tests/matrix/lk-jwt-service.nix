{
  pkgs,
  lib,
  ...
}:
{
  name = "lk-jwt-service";
  meta.maintainers = [ lib.maintainers.quadradical ];

  nodes.machine =
    let
      keyFilePath = "/etc/lk-jwt-service";
      keyFileContent = pkgs.writers.writeYAML "keys.yaml" {
        key = "f6lQGaHtM5HfgZjIcec3cOCRfiDqIine4CpZZnqdT5cE";
      };
    in
    { config, ... }: {
      systemd.services.setupSnakeoilKeyFile = {
        requiredBy = [ "lk-jwt-service.service" ];
        before = [ "lk-jwt-service.service" ];
        unitConfig = {
          type = "oneshot";
          RemainAfterExit = true;
        };
        serviceConfig.ExecStart = "${lib.getExe' pkgs.coreutils "cp"} ${keyFileContent} ${keyFilePath}";
      };

      services.lk-jwt-service = {
        enable = true;
        environment = {
          LIVEKIT_JWT_BIND = ":8000";
          LIVEKIT_URL = "wss://127.0.0.1:8100";
          LIVEKIT_KEY_FILE = keyFilePath;
          LIVEKIT_FULL_ACCESS_HOMESERVERS = "*";
        };
      };

      environment.systemPackages = [ config.services.lk-jwt-service.package ];
    };

  testScript = ''
    machine.wait_for_unit("lk-jwt-service.service")
    machine.wait_for_open_port(8000)
    machine.succeed('env LIVEKIT_JWT_BIND=:8000 healthcheck')
  '';
}
