{ config, lib, pkgs, ... }:
{
  config = {
    services.nginx.virtualHosts = {  
      "${config.networking.hostName}" = {
        default = true;
        forceSSL = true;
        root = "/var/www/root";
        serverAliases = [ "www.${config.networking.hostName}" ];

        extraConfig = ''
          add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
        '';
      };
    };
  };
}
