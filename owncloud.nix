{ pkgs, ... }:
{
  systemd.services.owncloud-docker = {
    wantedBy = [ "multi-user.target" ];
    description = "Containerized sonarqube server";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    preStart = ''${pkgs.coreutils}/bin/mkdir -p /var/lib/owncloud-docker/apps ; \
                 ${pkgs.coreutils}/bin/mkdir -p /var/lib/owncloud-docker/data ; \
                 ${pkgs.coreutils}/bin/mkdir -p /var/lib/owncloud-docker/config ; \
                 ${pkgs.coreutils}/bin/chown -R 1000 /var/lib/sonarqube-docker ; \
                 ${pkgs.docker}/bin/docker pull owncloud'';
    serviceConfig = {
      ExecStart = ''${pkgs.docker}/bin/docker run --name owncloud-docker -p 2712:80 \
                      -v /var/lib/owncloud-docker/apps:/var/www/html/apps \
                      -v /var/lib/owncloud-docker/config:/var/www/html/config \
                      -v /var/lib/owncloud-docker/data:/var/www/html/data \
                      owncloud
      '';
      ExecStop = ''${pkgs.docker}/bin/docker stop -t 2 owncloud-docker ; ${pkgs.docker}/bin/docker rm -f owncloud-docker'';
    };
  };
}


