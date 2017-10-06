{ pkgs, ... }:
{
  systemd.services.jupyter = {
    wantedBy = [ "multi-user.target" ];
    description = "Jupyter server";
    serviceConfig = {
      ExecStart = ''${pkgs.python36Packages.notebook}/bin/jupyter-notebook --no-browser \
                        --ip=0.0.0.0 \
                        --port=8888
      '';
    };
  };
}
