{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.lighttpd.nextcloud;
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
        ln -s /var/lib/nextcloud/{apps,data,config} $out;
      '';
  };

in
{
  options.services.lighttpd.nextcloud = {

    enable = mkEnableOption "Nextcloud in lighttpd";

    package = mkOption {
      type = types.package;
      default = pkgs.nextcloud;
      defaultText = "pkgs.nextcloud";
      description = "Nextcloud package to use.";
    };

    installPrefix = mkOption {
      type = types.path;
      default = "/var/lib/nextcloud";
      description = ''
        Where to install Nextcloud. By default, user files will be placed in
        the data/ directory below the <option>installPrefix</option> directory.
      '';
    };

    urlPrefix = mkOption {
      type = types.str;
      default = "/nextcloud";
      example = "/";
      description = ''
        The prefix below the web server root URL to serve Nextcloud.
      '';
    };

    vhostsPattern = mkOption {
      type = types.str;
      default = ".*";
      example = "(myserver1.example|myserver2.example)";
      description = ''
        A virtual host regexp filter. Change it if you want Nextcloud to only
        be served from some host names, instead of all.
      '';
    };

  };

  config = mkIf (config.services.lighttpd.enable && cfg.enable) {

    systemd.services.lighttpd.preStart =
      ''
        echo "Setting up Nextcloud in ${cfg.installPrefix}/"

        if [ ! -d ${cfg.installPrefix}/apps ]; then
          mkdir -p "${cfg.installPrefix}"/apps
          ${pkgs.rsync}/bin/rsync -a --checksum "${cfg.package}"/apps/* "${cfg.installPrefix}"/apps

          ${pkgs.postgresql}/bin/createuser --no-superuser --no-createdb --no-createrole "${dbUser}" || true
          ${pkgs.postgresql}/bin/createdb "${dbName}" -O "${dbUser}" || true
          ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -U postgres -d postgres -c "alter user ${dbUser} with password '${dbPassword}';" || true
          QUERY="CREATE TABLE appconfig (appid VARCHAR( 255 ) NOT NULL ,configkey VARCHAR( 255 ) NOT NULL ,configvalue VARCHAR( 255 ) NOT NULL); GRANT ALL ON appconfig TO ${dbUser}; ALTER TABLE appconfig OWNER TO ${dbUser};"
          ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -h "/tmp" -U postgres -d ${dbName} -Atw -c "$QUERY" || true
        fi
        mkdir -p "${cfg.installPrefix}"/{data,config}
        chown -R ${phpfpmUser}:${phpfpmUser} "${cfg.installPrefix}"
        chmod 755 "${cfg.installPrefix}"
        chmod 700 "${cfg.installPrefix}/data"
        chmod 750 "${cfg.installPrefix}/apps"
        chmod 700 "${cfg.installPrefix}/config"

        ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -h "/tmp" -U postgres -d ${dbName} -Atw -c "$QUERY" || true
      '';

    services.lighttpd = {
      enableModules = [ "mod_alias" "mod_fastcgi" "mod_access" "mod_setenv" ];
      extraConfig = ''
        mimetype.assign += (
            ".svg" => "image/svg+xml",
        )
        $HTTP["host"] =~ "${cfg.vhostsPattern}" {
            alias.url += ( "${cfg.urlPrefix}" => "${modifiedPackage}/" )
            # Prevent direct access to the data directory, like nextcloud warns
            # about in its admin interface "Security & setup warnings".
            $HTTP["url"] =~ "^${cfg.urlPrefix}/data" {
                url.access-deny = ("")
            }
            $HTTP["url"] =~ "^${cfg.urlPrefix}" {
                fastcgi.server = (
                    ".php" => (
                        "phpfpm-nextcloud" => (
                            "socket" => "${phpfpmSocketName}",
                        )
                    )
                )
            }
            # Recommended setting (Nextcloud warns about this in the admin interface)
            $HTTP["scheme"] == "https" {
                setenv.add-response-header += (
                    "Strict-Transport-Security" => "max-age=15552000; includeSubDomains; preload"
                )
            }
        }
      '';
    };

    services.phpfpm.poolConfigs = {
      nextcloud = ''
        listen = ${phpfpmSocketName}
        listen.owner = lighttpd
        listen.group = lighttpd
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

    users.extraUsers.lighttpd.extraGroups = [ phpfpmGroup ];

    users.extraGroups."${phpfpmGroup}" = {};

    users.extraUsers."${phpfpmUser}" = {
      group = phpfpmGroup;
      description = "Nextcloud server user";
    };
  };
}
