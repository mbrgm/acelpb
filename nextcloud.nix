# Owncloud service on docker.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nextcloud;
  dbName = "nextcloud";
  dbUser = "nextcloud";
  dbPassword = "bobisgreat76times";
  phpfpmSocketName = "/run/phpfpm/nextcloud.sock";
  phpfpmUser = "nextcloud";
  phpfpmGroup = "nextcloud";
  modifiedPackage = pkgs.stdenv.mkDerivation rec {
    name = "my-nextcloud";
    src = cfg.package;

    installPhase =
      ''
        mkdir -p $out
        find . -maxdepth 1 -execdir cp -r '{}' $out \;
        rm -rf $out/{apps,data,config};
        ln -s ${cfg.installPrefix}/{apps,config} $out;
      '';
  };

in
{
  options.services.nextcloud = {

    enable = mkEnableOption "Nextcloud instance";

    package = mkOption {
      type = types.package;
      default = pkgs.nextcloud;
      defaultText = "pkgs.nextcloud";
      description = "Nextcloud package to use.";
    };

    installPrefix = mkOption {
      type = types.path;
      default = "/var/www/nextcloud";
      description = ''
        Where to install Nextcloud. By default, user files will be placed in
        the data/ directory below the <option>installPrefix</option> directory.
      '';
    };

    # vhosts = mkOption {
    #   type = types.str;
    #   default = [ "cloud.${config.networking.hostName}" ];
    #   example = [ "owncloud.example1.org" "nextcloud.example2.org" "cloud.example3.org" ];
    #   description = ''
    #     A virtual host regexp filter. Change it if you want Nextcloud to only
    #     be served from some host names, instead of all.
    #   '';
    # };

    # serverServicec = mkOption {
    #   type = types.str;
    #   default = config.services.nginx;
    #   defaultText = "config.services.nginx";
    #   example = [ "owncloud.example1.org" "nextcloud.example2.org" "cloud.example3.org" ];
    #   description = ''
    #     A virtual host regexp filter. Change it if you want Nextcloud to only
    #     be served from some host names, instead of all.
    #   '';
    # };

  };

  config = mkIf (cfg.enable) {

    systemd.services.phpfpm-nextcloud.preStart =
      ''
        echo "Setting up Nextcloud in ${cfg.installPrefix}/"
        if [ ! -d ${cfg.installPrefix}/apps ]; then
          mkdir -p "${cfg.installPrefix}"/apps
          ${pkgs.rsync}/bin/rsync -a --checksum "${cfg.package}"/apps/* "${cfg.installPrefix}"/apps
        fi
        mkdir -p "${cfg.installPrefix}"/{data,config}
        chown -R ${phpfpmUser}:${phpfpmUser} "${cfg.installPrefix}"
        chmod 755 "${cfg.installPrefix}"
        chmod 700 "${cfg.installPrefix}/data"
        chmod 750 "${cfg.installPrefix}/apps"
        chmod 700 "${cfg.installPrefix}/config"
      '';


    services.phpfpm.poolConfigs = {
      nextcloud = ''
        listen = ${phpfpmSocketName}
        listen.owner = nginx
        listen.group = nginx
        user = ${phpfpmUser}
        group = ${phpfpmGroup}
        pm = dynamic
        pm.max_children = 75
        pm.start_servers = 10
        pm.min_spare_servers = 5
        pm.max_spare_servers = 20
        pm.max_requests = 500
      '';
    };

    users.extraUsers.nginx.extraGroups = [ phpfpmGroup ];

    users.extraGroups."${phpfpmGroup}" = {};

    users.extraUsers."${phpfpmUser}" = {
      group = phpfpmGroup;
      description = "Nextcloud server user";
    };

    services.nginx = {
      commonHttpConfig = ''
        upstream php-handler {
          server unix:${phpfpmSocketName};
        }
      '';

      virtualHosts = {  
        "cloud.${config.networking.hostName}" = {
          forceSSL = true;
          root = modifiedPackage;
          serverAliases = [ "owncloud.${config.networking.hostName}" ];

          extraConfig = ''
            add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";

            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection "1; mode=block";
            add_header X-Robots-Tag none;
            add_header X-Download-Options noopen;
            add_header X-Permitted-Cross-Domain-Policies none;

            location = /robots.txt {
              allow all;
              log_not_found off;
              access_log off;
            }

            location = /.well-known/carddav {
              return 301 $scheme://$host/remote.php/dav;
            }
            location = /.well-known/caldav {
              return 301 $scheme://$host/remote.php/dav;
            }

            # set max upload size
            client_max_body_size 512M;
            fastcgi_buffers 64 4K;

            # Enable gzip but do not remove ETag headers
            gzip on;
            gzip_vary on;
            gzip_comp_level 4;
            gzip_min_length 256;
            gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
            gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

            location / {
                rewrite ^ /index.php$uri;
            }

            location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
                deny all;
            }
            location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
                deny all;
            }

            location ~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+)\.php(?:$|/) {
                fastcgi_split_path_info ^(.+\.php)(/.*)$;
                include ${pkgs.nginx}/conf/fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $fastcgi_path_info;
                fastcgi_param HTTPS on;
                #Avoid sending the security headers twice
                fastcgi_param modHeadersAvailable true;
                fastcgi_param front_controller_active true;
                fastcgi_pass unix:${phpfpmSocketName};
                fastcgi_intercept_errors on;
                fastcgi_request_buffering off;
            }

            location ~ ^/(?:updater|ocs-provider)(?:$|/) {
                try_files $uri/ =404;
                index index.php;
            }

            location ~ \.(?:css|js|woff|svg|gif)$ {
                try_files $uri /index.php$uri$is_args$args;
                add_header Cache-Control "public, max-age=15778463";

                add_header X-Content-Type-Options nosniff;
                add_header X-XSS-Protection "1; mode=block";
                add_header X-Robots-Tag none;
                add_header X-Download-Options noopen;
                add_header X-Permitted-Cross-Domain-Policies none;
                access_log off;
            }

            location ~ \.(?:png|html|ttf|ico|jpg|jpeg)$ {
                try_files $uri /index.php$uri$is_args$args;
                access_log off;
            }
          '';
          };
      };
    };
  };
}
