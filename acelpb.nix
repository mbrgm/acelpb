# Configuration file for acelpb.nix
{ config, pkgs, ... }:
let
  myCfg = builtins.fromJSON (builtins.readFile ./private/config.json);

in
{

  users.extraUsers.phpfpm = {
    description = "PHP FastCGI user";
    uid = 2222;
    group = "phpfpm";
  };

  users.extraGroups.phpfpm.gid = 2222;

  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  networking.nameservers = [ "208.67.222.222" "208.67.220.220" "8.8.8.8" "4.4.4.4" "213.186.33.99" ];
  # Select internationalisation properties.
  i18n.defaultLocale = "fr_BE.UTF-8";
  time.timeZone = "Europe/Brussels";

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    bashCompletion
    git
    git-hub
    squid
    vim
    wget
  ];

  virtualisation.docker.enable = true;

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

  services = {

    jenkins = {
      enable = true;
      port = 2711;
      listenAddress = "localhost";
      extraGroups = [ "docker" ];
      packages = [ pkgs.stdenv pkgs.git pkgs.jdk config.programs.ssh.package pkgs.nix pkgs.sbt pkgs.maven pkgs.vim pkgs.python3 pkgs.docker pkgs.pythonPackages.docker_compose ];
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql94;
      enableTCPIP = true;
      authentication = ''
        host ownclouddock ownclouddock 172.17.0.0/16 md5
        host sonarqube sonarqube 172.17.0.0/16 md5
      '';
    };

    nginx = {

      enable = true;

      httpConfig = ''
        server {
          listen 80;
          server_name *.acelpb.com;

          location /.well-known/acme-challenge {
            root /var/www/acme.pastespace.org;
          }

          location / {
            return 301 https://$host$request_uri;
          }
        }
      
        server {
          listen 80	default_server;
          listen [::]:80	default_server;
          server_name _;

          location /.well-known/acme-challenge {
            root /var/www/acme.pastespace.org;
          }
      
          location / {
            return 301 https://www.acelpb.com;
          }
        }
 
        server {
          server_name sonarqube.acelpb.com;
          listen 443;
          listen [::]:443;
          
          ssl	on;
          # ssl_certificate  /var/lib/acme/acelpb.com/fullchain.pem;
          # ssl_certificate_key /var/lib/acme/acelpb.com/key.pem;
          ssl_certificate  /var/lib/startssl/acelpb.com/sonarqube/fullchain.pem;
          ssl_certificate_key /var/lib/startssl/acelpb.com/sonarqube/key.pem;
          
          location / {
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;
            proxy_redirect http:// https://;
            proxy_pass http://localhost:9000;
          }
        }

        server {
          server_name jenkins.acelpb.com;
          listen 443;
          listen [::]:443;
          
          ssl	on;
          ssl_certificate  /var/lib/acme/acelpb.com/fullchain.pem;
          ssl_certificate_key /var/lib/acme/acelpb.com/key.pem;
          
          location / {
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;
            proxy_redirect http:// https://;
            proxy_pass http://localhost:2711;
          }
        }
 
        server {
          listen 443 ssl;
          listen [::]:443 ssl;
          server_name owncloud.acelpb.com;
       
          ssl_certificate  /var/lib/acme/acelpb.com/fullchain.pem;
          ssl_certificate_key /var/lib/acme/acelpb.com/key.pem; 
        
          add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";

          # set max upload size
          client_max_body_size 10G;
        
          gzip off;

          location / {
            proxy_pass http://localhost:2712;
          }
        }

        server {
          server_name jcm.acelpb.com;
          listen 443;
          listen [::]:443;
          
          ssl	on;
          ssl_certificate  /var/lib/acme/acelpb.com/fullchain.pem;
          ssl_certificate_key /var/lib/acme/acelpb.com/key.pem;
          
          location / {
            root /var/www/jcm;
          }
        }

        server {
          server_name jess.acelpb.com;
          listen 443;
          listen [::]:443;
          
          ssl	on;
          ssl_certificate  /var/lib/acme/acelpb.com/fullchain.pem;
          ssl_certificate_key /var/lib/acme/acelpb.com/key.pem;
          
          location / {
            root /var/www/jess;
          }
        }

        server {
          server_name *.acelpb.com acelpb.com;
          listen 443;
          listen [::]:443;
          
          ssl	on;
          ssl_certificate  /var/lib/acme/acelpb.com/fullchain.pem;
          ssl_certificate_key /var/lib/acme/acelpb.com/key.pem;
          
          location / {
            root /var/www/root;
          }
        }
      '';

    };

    openssh.enable = true;

    xserver.enable = false;

  };

  security.acme = {
    certs = {
      "acelpb.com" = {
        webroot = "/var/www/acme.pastespace.org";
        extraDomains = {
          "jess.acelpb.com" = null;
          "jcm.acelpb.com" = null;
          "sonarqube.acelpb.com" = null;
          "owncloud.acelpb.com" = null;
          "www.acelpb.com" = null;
          "jenkins.acelpb.com" = null;
        };
      email = "a.borsu@gmail.com";
      postRun = "systemctl reload nginx.service";
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.aborsu = {
    description = "Augustin Borsu";
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDT6nGess3TiV7KCZqCzv7wqny1GYsH9bkiT6Vae2Xo8I0YgvkqD6C/QszEk28lu7CMsm2bb8bDkYKm6Ce8jTin+hyobVvlxC5fAYZK8oE4AKn1rHkDqq1wnJwTRIrB97Nc2077BHAv2OLh5G2A/uazkIWxcoIBJNne9fFXY8B98DoB4WsDtBxj7OFnDIm27qX2VtScrr7U95SGjKN6F6MUyFEcFu9GhkXLs8BS/G8oVfSSmHFTBpIeNQ69BX7NXb+mWP98ouD4yGsRSiKZHdSwjVWI1JU4MO0tGkRAZXY2p0vacp+ePh6r0ESHbVUazX4Vof7p1i35VlIg850C9iAq6xhx3b59lYVk6AyAhfj0lujz10+00EkHy6l9BmtzBV1mFmTJpMPFQQ00Hup92ihMyGNglgPs23s3lR8iLjQ7gDpNohHmFKBFSG2Jp2tEhnfuH3tz3NWn4pXPyIUWs5znRb9Sup7/XoRtelZrSEai/EUPeP5RysYMsxiRoms47rD8FWTE0hQFUrHjQzk+RGUd/OCBv3LPR6wiwfRmdIJnNg6yDahNsRiJ3bCqtwjRkdpZ1ezLAzgwNVaNRWq4EEHMfeQ7Oud7yjgdqhb0vvAy5J4ZSHM05+77sNQoAPVEYlEhYJwyfukDMprkImypVhdOplkGaqTxMDvPY46ipGjK5Q== aborsu@mbpro-gus-Ven 16 oct 2015 10:13:03 CEST" ];
  };

  users.extraUsers.jcm = {
    isNormalUser = true;
    description = "Jean-Christophe Maigrot";
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKjZS/Z37B0kZ1jfWXNQGEsNU9LM2Y2YcghHqFiO5IuWSu+XzFoRdeeFfcsfF/j5uQbWy+23z2CvuivsdNAdqS4Gl7X+wAg9pG9A+h9BRWEjGN/Llpq0NOPeiFSgLOxFuu4VOU6QzVPpgSLLWqM+av3Ib8q5UHCE49CPIcptwnOFmSQtvk6nDtbZpb9WA+MnL+xOp1P1nXu9JbpUUvCcZuqYWSrg+OMEkFv9ujTzK9uEnUMgQq4N7o4swUpXcs1dKt9Ev96Pr+GlSmcr567l+Ach2nX6+4l01ygzCCzEEzyodFT8qf8xGw3Aak+38Bu/qcqtHXNxPQ4IQgFyhyiyFl jcm@acelpb-" ];
  };

  users.extraUsers.jess = {
    isNormalUser = true;
    description = "";
    openssh.authorizedKeys.keys = [ ];
  };

}


