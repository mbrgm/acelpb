# Owncloud service on docker.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.acelpb.owncloud;

in

{
  ###### interface
  options.acelpb.owncloud = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "This option enables owncloud in a docker image.";
      };

      hostname = mkOption {
        type = types.str;
        description = "Owncloud hostname";
      };

      port = mkOption {
        type = types.int;
        default = 2712;
        description = "Local port used by the docker container.";
      };

      forceSSL = mkOption {
        type = types.bool;
        description = "Local port used by the docker container.";
      };
  };

  ###### implementation
  config = mkIf cfg.enable (mkMerge [{
      virtualisation.docker.enable = true;
      services.nginx.enable = true;
      services.nginx.virtualHosts = {
        "${cfg.hostname}" = {
          forceSSL = cfg.forceSSL;
          enableACME = cfg.forceSSL;
          locations."/" = {
            proxyPass = "http://localhost:${toString cfg.port}";
          };
        };
      };
      systemd.services.owncloud-docker = {
        wantedBy = [ "multi-user.target" ];
        description = "Containerized owncloud server";
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        preStart = ''${pkgs.docker}/bin/docker rm -f owncloud-docker || true;
                     ${pkgs.coreutils}/bin/mkdir -p /var/lib/owncloud-docker/apps ; \
                     ${pkgs.coreutils}/bin/mkdir -p /var/lib/owncloud-docker/data ; \
                     ${pkgs.coreutils}/bin/mkdir -p /var/lib/owncloud-docker/config ; \
                     ${pkgs.coreutils}/bin/chown -R 1000 /var/lib/owncloud-docker'';
        serviceConfig = {
          ExecStart = ''${pkgs.docker}/bin/docker run --name owncloud-docker -p ${toString cfg.port}:80 \
                          -v /var/lib/owncloud-docker/apps:/var/www/html/apps \
                          -v /var/lib/owncloud-docker/config:/var/www/html/config \
                          -v /var/lib/owncloud-docker/data:/var/www/html/data \
                          owncloud:9.0
          '';
          ExecStop = ''${pkgs.docker}/bin/docker stop -t 2 owncloud-docker'';
        };
      };
    }
  ]);
}
