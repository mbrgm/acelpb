{ config, pkgs, ... }:
{
  services = {
    nginx.enable = true;
    nginx.virtualHosts = {
      "jenkins.acelpb.com" = {
        forceSSL = true;
        enableACME = true;
        root = pkgs.jenkins;
        extraConfig = ''
          ignore_invalid_headers off;
        '';
        locations = {
          "~ \"^/static/[0-9a-fA-F]{8}\/(.*)$\"" = {
            extraConfig = "rewrite \"^/static/[0-9a-fA-F]{8}\/(.*)\" /$1 last;";
          };
          "/userContent" = {
            root = /var/lib/jenkins;
            extraConfig = ''
              if (!-f $request_filename){
                rewrite (.*) /$1 last;
                break;
              }
              sendfile on;
            '';
          };
          "@jenkins" = {
            proxyPass = "http://localhost:${toString 2711}";
            extraConfig = ''
              sendfile off;
              proxy_redirect     default;

              proxy_set_header   Host             $host;
              proxy_set_header   X-Real-IP        $remote_addr;
              proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
              proxy_max_temp_file_size 0;

              #this is the maximum upload size
              client_max_body_size       10m;
              client_body_buffer_size    128k;

              proxy_connect_timeout      90;
              proxy_send_timeout         90;
              proxy_read_timeout         90;

              proxy_buffer_size          4k;
              proxy_buffers              4 32k;
              proxy_busy_buffers_size    64k;
              proxy_temp_file_write_size 64k;
            '';
          };
          "/" = {
            extraConfig = ''
              if ($http_user_agent ~* '(iPhone|iPod)') {
                  rewrite ^/$ /view/iphone/ redirect;
              }

              try_files $uri @jenkins;
            '';
          };
        };
      };
    };

    jenkins = {
      enable = true;
      port = 2711;
      listenAddress = "localhost";
      extraGroups = [ "docker" ];
      packages = [
        pkgs.coreutils
        pkgs.stdenv
        pkgs.git
        pkgs.jdk
        config.programs.ssh.package
        pkgs.nix
        pkgs.docker
        pkgs.bash
        pkgs.yarn
        pkgs.nodejs
      ];
    };
  };
}


