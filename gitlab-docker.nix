# Gitlab service on docker.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.acelpb.gitlab;

in

{
  ###### interface
  options.acelpb.gitlab = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "This option enables gitlab in a docker image.";
    };

    hostname = mkOption {
      type = types.str;
      description = "Gitlab hostname";
    };

    port = mkOption {
      type = types.int;
      default = 2720;
      description = "Local port used by the gitlab docker container.";
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
      systemd.services.gitlab-docker = {
        wantedBy = [ "multi-user.target" ];
        description = "Containerized gitlab server";
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        preStart = ''${pkgs.docker}/bin/docker rm -f gitlab || true;
                     ${pkgs.coreutils}/bin/mkdir -p /var/lib/gitlab/config ; \
                     ${pkgs.coreutils}/bin/mkdir -p /var/lib/gitlab/logs ; \
                     ${pkgs.coreutils}/bin/mkdir -p /var/lib/gitlab/data ; \
                     ${pkgs.coreutils}/bin/chown -R 1000 /var/lib/gitlab'';
        serviceConfig = {
          ExecStart = ''${pkgs.docker}/bin/docker run --name gitlab \
                          --hostname ${cfg.hostname} \
                          -publish ${toString cfg.port}:80 \
                          -publish 22:22 \
                          -p ${toString cfg.port}:80 \
                          --volume /var/lib/gitlab/config:/etc/gitlab \
                          --volume /var/lib/gitlab/logs:/var/log/gitlab \
                          --volume /var/lib/gitlab/data:/var/opt/gitlab \
                          gitlab/gitlab-ce:latest
          '';
          ExecStop = ''${pkgs.docker}/bin/docker stop -t 2 gitlab'';
        };
      };
    }
  ]);
}
