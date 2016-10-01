# Configuration file for acelpb.nix
{ config, pkgs, ... }:
let
  myCfg = builtins.fromJSON (builtins.readFile ./private/config.json);

in
{
  imports =
    [
      ./sonarqube.nix
      ./owncloud.nix
      ./jenkins.nix
    ];

  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 3306 5432 7676 ];
  networking.nameservers = [ "208.67.222.222" "208.67.220.220" "8.8.8.8" "4.4.4.4" "213.186.33.99" ];

  # Select internationalisation properties.
  i18n.defaultLocale = "fr_BE.UTF-8";
  time.timeZone = "Europe/Brussels";

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    bashCompletion
    perlPackages.CGI
    perlPackages.DBI
    perlPackages.DBDmysql
    git
    git-hub
    perl
    squid
    vim
    wget
  ];

  virtualisation.docker.enable = true;

  services = {

    mysql = {
      enable = true;
      package = pkgs.mariadb;
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

    fcgiwrap = {
      enable = true;
    };

    phpfpm = {
      poolConfigs = {
        deadpool = ''

          listen = /run/phpfpm/deadpool
          listen.owner = nginx
          listen.group = nginx
          listen.mode = 0660
          user = nginx
          pm = dynamic
          pm.max_children = 75
          pm.start_servers = 10
          pm.min_spare_servers = 5
          pm.max_spare_servers = 20
          pm.max_requests = 500

          php_flag[display_errors] = on
          php_value[date.timezone] = "Europe/Berlin"
          php_admin_value[error_log] = /var/log/phpfpm_deadpool.log
          php_admin_flag[log_errors] = on
          php_admin_value[open_basedir] = /var/www
        '';
      };
    };

    nginx = {

      enable = true;

      httpConfig = ''
        error_log /var/log/nginx/error.log;

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
            proxy_pass http://localhost:2713;
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

          root /var/www/jcm;
          location / {
            index    index.html index.htm;
          }

          location ~ \.php$ {
             index    index.php
             try_files $uri =404;
             include ${pkgs.nginx}/conf/fastcgi_params;
             fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
             fastcgi_pass   unix:/run/phpfpm/deadpool;
             fastcgi_index  index.php;
          }
        }

        server {
          server_name jess.acelpb.com;
          listen 443;
          listen [::]:443;

          access_log /var/log/nginx/jess-access.log;
          error_log /var/log/nginx/jess-error.log;

          ssl	on;
          ssl_certificate  /var/lib/acme/acelpb.com/fullchain.pem;
          ssl_certificate_key /var/lib/acme/acelpb.com/key.pem;

          root /var/www/jess;
          location / {
            index    index.html index.htm index.php index.pl;
          }

          location ~ \.php$ {
             try_files $uri =404;
             include ${pkgs.nginx}/conf/fastcgi_params;
             fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
             fastcgi_pass   unix:/run/phpfpm/deadpool;
             fastcgi_index  index.php;
          }

          location ~ \.pl$ {
             try_files $uri =404;
             include ${pkgs.nginx}/conf/fastcgi_params;
             fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
             fastcgi_pass   unix:/run/fcgiwrap.sock;
             fastcgi_index  index.pl;
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
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDT6nGess3TiV7KCZqCzv7wqny1GYsH9bkiT6Vae2Xo8I0YgvkqD6C/QszEk28lu7CMsm2bb8bDkYKm6Ce8jTin+hyobVvlxC5fAYZK8oE4AKn1rHkDqq1wnJwTRIrB97Nc2077BHAv2OLh5G2A/uazkIWxcoIBJNne9fFXY8B98DoB4WsDtBxj7OFnDIm27qX2VtScrr7U95SGjKN6F6MUyFEcFu9GhkXLs8BS/G8oVfSSmHFTBpIeNQ69BX7NXb+mWP98ouD4yGsRSiKZHdSwjVWI1JU4MO0tGkRAZXY2p0vacp+ePh6r0ESHbVUazX4Vof7p1i35VlIg850C9iAq6xhx3b59lYVk6AyAhfj0lujz10+00EkHy6l9BmtzBV1mFmTJpMPFQQ00Hup92ihMyGNglgPs23s3lR8iLjQ7gDpNohHmFKBFSG2Jp2tEhnfuH3tz3NWn4pXPyIUWs5znRb9Sup7/XoRtelZrSEai/EUPeP5RysYMsxiRoms47rD8FWTE0hQFUrHjQzk+RGUd/OCBv3LPR6wiwfRmdIJnNg6yDahNsRiJ3bCqtwjRkdpZ1ezLAzgwNVaNRWq4EEHMfeQ7Oud7yjgdqhb0vvAy5J4ZSHM05+77sNQoAPVEYlEhYJwyfukDMprkImypVhdOplkGaqTxMDvPY46ipGjK5Q== aborsu@mbpro-gus-Ven 16 oct 2015 10:13:03 CEST"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD3khGNPxaYdMrWPc37tlp26hg7/8ZU4CAiwu1s1Vb9cLjzQ6+efDwetn4fbR6lVuF1GeoPfWQJX/U5iaBajy7VbFpTCuZEfcJjmslRBrWU3dw4683e7rSBp6bX9Gi5BGNG+fqQFWNZqkaRye0CfWhb+SdZSJuFk6gZCj2MXl3tP9miDNvwjZ/KpmQAaxzMm9Gw7UIEO0eVClD2Ng7y7fdfIS8u6mKzqgWN0Hr8NmlpRE7jJ6XlrkYx+0rET7BDe1YKuOwFscxZmZi+cA5gAb+zwXX+upcu6pMq7brgz1hpCuJlBXJG7EGq1XqXl9MEqxT9RMfKL0fO8cS2nM7wHA3Sk/Qm+EUEKE9f/gPu2aQNSujSqc+FifHZBQicrD1fF/Ls39nIWpWrPTK2/bOJvnNfe1NkWzikRuVdVhCeMZOQfTHmhOrykh1YKPYyPPwyosPAmhbalqMi++hj7btEJhynXKRyFuyeJ7Q3xR0ETeeLPZH404KzFa0pCR9P0JSFrbHlOrCxN3wsYTFpctUkKMF4g/TivZk2xBWnJED4hOwDqwXMeUwwg8By7ZsTQsHYoJ/ukk2uANQPYCboE7C/OMOWHXxU28yMm9Ule3TfkKrzgrHVetZI/AIR7gq/52a/dFLThcB2e06mCqwAEAiXQyffliGJXg63tgUzQF/U+Jn0bQ== a.borsu@gmail.com"
    ];
  };

  users.extraUsers.jcm = {
    isNormalUser = true;
    description = "Jean-Christophe Maigrot";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDgI+1SB4q+Lvo+BNvYONgKW83qoamw8yuUFXMsXciNbgMqI5X9/tlGtnaHOKU6FO1a0F423nJu2ZgK0Cn7ZggUEpIxZvA36pXeYNNkQExdUEEuEhcmdHzlAgnh45qGCElUH0zYeor0xyH6it0/anOe7Pb+NFjMTFfllWHdD/JsDt3/n4CrRActsCrgjKA9dGKiao8IsKocJ3KT4z0aywDzwg8XlwxQPIWJ4f8pbPYG8xDNafxjl0S/NSGv6SJyPK2RuF08JkRUgmqJ5tB3JavUWHMJYjH5zvjMa5iPwCPTzp4odrj+kp4aDflqivuraDQknpQMZ9NvTCIKhksXnLsD bigboss@bigboss-laptop-hp"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKjZS/Z37B0kZ1jfWXNQGEsNU9LM2Y2YcghHqFiO5IuWSu+XzFoRdeeFfcsfF/j5uQbWy+23z2CvuivsdNAdqS4Gl7X+wAg9pG9A+h9BRWEjGN/Llpq0NOPeiFSgLOxFuu4VOU6QzVPpgSLLWqM+av3Ib8q5UHCE49CPIcptwnOFmSQtvk6nDtbZpb9WA+MnL+xOp1P1nXu9JbpUUvCcZuqYWSrg+OMEkFv9ujTzK9uEnUMgQq4N7o4swUpXcs1dKt9Ev96Pr+GlSmcr567l+Ach2nX6+4l01ygzCCzEEzyodFT8qf8xGw3Aak+38Bu/qcqtHXNxPQ4IQgFyhyiyFl jcm@acelpb-"
    ];
  };

  users.extraUsers.jess = {
    isNormalUser = true;
    description = "";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAzZlG8Vp486YVQFPpDvaZnQaq/qol4EEH1DpHvvapjeQZx8xMA0cnEXBW4DHU/GyXkAS16S3xJoJq6LD5Kb6s428I7BWw1lG4OtEh6lrkssQOeMy/TvlaJi4Uy3Dv6oXJDv87epsx9T0PcQ03PdXQchn/REBY/wFX4YlJ3KQylYBNkb1Yhan9MED/3LjU2xOrMgs56Ta6jvzciOlA5gOvOCeUdSxd1Q16zcV+rOAvn6HdGPoon6Q4rclzoUvPofxfcnVgDuKYT5LO/aH35eFmKBruYVrZ/wJKm5g4kZtaHbThfyTO9j+U3pTWBrm4EXSAB/5ezu1NaFpSBz2ReQaJ3Q== rsa-key-20160621"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDI8bqlV1Mt0fvDo9GNc9GfpcWKEqR6G4UNcHdZkHJNPcrcyOC2UKirAnOCZTZ2LLBVKrjyMrpJSzHcgYMf/AWN1Rfqv2iWOzdsXrXKnQ2KcbGlt+HGVPmMd1aW8TtZTDWI3Ui2sjqe0QliLbiqMF7v1YfnZyiHJsYpzr3WphXVqrBfw5l7j/2LHE/jYUhExDoEUpocnJp61GvHAo0mEmy3WUILfNMNVi48yBpkl2b0sTmp9NEHpCiOtRbbeHKF0CsjlQJAwUo4DekZ8xUun4gEAGBJWbbLdpmJ9m3m8UlKKO1PpRcgIgaPBkeZKuHllmu/uTXbt82cj1CbnuDNo8ClxaPq7wKRDeHYtZS81UwOhQEyRL+R23Ri3zNGoDTDQoTCS81y+flXk9INferB/4Q/j4gAAae/sXj3EbjsLw6ryTQ1NJhyH40o7/bHBGUFftEJHoYcNLUOQwjNFr9cl7w/IgJtKkrJMLCDDGf2Xbwy8ZMq/rNnysLRO98FMnirtyxFzqyXCnijcaep8+e462lYlHKzTNALP3s3qL8TAUxkBCuHNR2s/by7+iBE318Qh2RMK5GhYoPjDznKtV9g2Kw1zYdCbAmaSHxXQHwJtHpZEJUcURxO3c06AdCkQM64UGrVhw99M68Qs5jEY2UAU9hjdKXYtS0A9csWr2AezNm6lQ== jessica@JH"
    ];
  };
}


