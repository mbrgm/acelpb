{ config, lib, pkgs, ... }:
let jupyterhub = (import ./package.nix);
in
{
  config = {
    services.nginx.virtualHosts = {
      "jupyter.${config.networking.hostName}" = {
        forceSSL = true;
        extraConfig = ''
          location / {

            proxy_pass http://localhost:8888;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header Host $http_host;
            proxy_http_version 1.1;
            proxy_redirect off;
            proxy_buffering off;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_read_timeout 86400;
          }
        '';
      };
    };

    systemd.services.jupyterhub = {
      wantedBy = [ "multi-user.target" ];
      description = "Jupyter server";
      path = [
        "/var/jupyterhub"
        "${pkgs.nodejs}"
      ];
      preStart = ''
        mkdir -p /var/jupyterhub
        ${pkgs.nodejs}/bin/npm install --prefix /var/jupyterhub -g configurable-http-proxy
      '';
      serviceConfig = {
        WorkingDirectory = "/var/jupyterhub";
        ExecStart = ''${jupyterhub}/bin/jupyterhub \
          --port 8888 \
          --log-level DEBUG \
          --no-db
        '';
      };
    };
  };
}
