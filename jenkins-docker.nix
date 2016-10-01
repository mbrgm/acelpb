{ pkgs, ... }:
{
  systemd.services.jenkins-docker = {
    wantedBy = [ "multi-user.target" ];
    description = "Containerized jenkins server";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    preStart = ''${pkgs.coreutils}/bin/mkdir -p /var/lib/jenkins-docker ; \
                 ${pkgs.coreutils}/bin/chown -R 1000 /var/lib/jenkins-docker ; \
                 ${pkgs.docker}/bin/docker pull jenkinsci/jenkins'';
    serviceConfig = {
      ExecStart = ''${pkgs.docker}/bin/docker run --name jenkins-docker -p 2711:8080 \
                      -v /var/lib/jenkins-docker:/var/jenkins_home \
                      jenkinsci/jenkins
      '';
      ExecStop = ''${pkgs.docker}/bin/docker stop -t 2 jenkins-docker ; ${pkgs.docker}/bin/docker rm -f jenkins-docker'';
    };
  };
}


