{ config, lib, pkgs, ... }:
{
  config = {
    services.nginx.virtualHosts = {
      "jupyter.${config.networking.hostName}" = {
        forceSSL = true;
        locations."/" = {
            proxyPass = "http://localhost:8888";
        };
      };
    };
    systemd.services.jupyter = {
      wantedBy = [ "multi-user.target" ];
      description = "Jupyter server";
      serviceConfig = {
        ExecStart = ''${pkgs.python36Packages.notebook}/bin/jupyter-notebook --no-browser \
                        --allow-root \
                        --ip=localhost \
                        --port=8888
        '';
      };
    };
  };
}
