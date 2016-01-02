{
  acelpb =
    { config, pkgs, ... }:
    {
      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 2048;
      deployment.virtualbox.headless = true;

      # deployment.targetHost = "192.168.56.10";
      # networking.interfaces.eth1.ip4 = [ { address = "192.168.56.10"; prefixLength = 24; } ];

      imports = [ ./acelpb.nix ];
    };
}
