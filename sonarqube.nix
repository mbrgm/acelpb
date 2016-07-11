{ config, pkgs, ... }:

{
  systemd.services.sonarqube-docker = {
    wantedBy = [ "multi-user.target" ];
    description = "Containerized sonarqube server";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    preStart = ''${pkgs.coreutils}/bin/mkdir -p /var/lib/sonarqube-docker/conf ; \
                 ${pkgs.coreutils}/bin/mkdir -p /var/lib/sonarqube-docker/data ; \
                 ${pkgs.coreutils}/bin/mkdir -p /var/lib/sonarqube-docker/extensions ; \
                 ${pkgs.coreutils}/bin/chown -R 1000 /var/lib/sonarqube-docker ; \
                 ${pkgs.docker}/bin/docker pull sonarqube'';
    serviceConfig = {
      ExecStart = ''${pkgs.docker}/bin/docker run --name sonarqube-docker -p 9000:9000 -p 9092:9092 \
                      -v /var/lib/sonarqube-docker/conf:/opt/sonarqube/conf \
                      -v /var/lib/sonarqube-docker/data:/opt/sonarqube/data \
                      -v /var/lib/sonarqube-docker/extensions:/opt/sonarqube/extensions \
                      -e SONARQUBE_JDBC_USERNAME=sonarqube \
                      -e SONARQUBE_JDBC_PASSWORD=bobisgreat \
                      -e SONARQUBE_JDBC_URL=jdbc:postgresql://acelpb.com/sonarqube \
                      sonarqube
      '';
      ExecStop = ''${pkgs.docker}/bin/docker stop -t 2 sonarqube-docker ; ${pkgs.docker}/bin/docker rm -f sonarqube-docker'';
    };
  };
}
