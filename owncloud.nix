{ pkgs, ... }:
{
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
      ExecStart = ''${pkgs.docker}/bin/docker run --name owncloud-docker -p 2712:80 \
                      -v /var/lib/owncloud-docker/apps:/var/www/html/apps \
                      -v /var/lib/owncloud-docker/config:/var/www/html/config \
                      -v /var/lib/owncloud-docker/data:/var/www/html/data \
                      owncloud:9.0
      '';
      ExecStop = ''${pkgs.docker}/bin/docker stop -t 2 owncloud-docker'';
    };
  };
}
