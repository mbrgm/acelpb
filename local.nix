{
  acelpb =
    { config, pkgs, ... }:
    let
      myCfg = builtins.fromJSON (builtins.readFile ./config/local.json);
    in
    {

      acelpb.owncloud.enable = true;
      acelpb.owncloud.hostname = "owncloud.${myCfg.hostname}";
      acelpb.owncloud.forceSSL = myCfg.owncloud.forceSSL;

      services.nginx.virtualHosts = myCfg.virtualHosts;

      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 2048;
      deployment.virtualbox.headless = true;

      # deployment.targetHost = "192.168.56.10";
      # networking.interfaces.eth1.ip4 = [ { address = "192.168.56.10"; prefixLength = 24; } ];

      imports = [ ./acelpb.nix ];
    };
}
