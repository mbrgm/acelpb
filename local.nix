{
  acelpb =
    { config, pkgs, ... }:
    {

      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 2048;
      deployment.virtualbox.headless = true;

      imports = [ ./acelpb.nix ];

      networking.hostName = "localacelpb.com";

      environment.systemPackages = [ pkgs.vim ];
    };
}
