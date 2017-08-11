{
  acelpb =
    { config, lib, pkgs, ... }:
    {
      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 2048;
      deployment.virtualbox.headless = true;

      imports = [ 
        ./../acelpb.nix 
        ./../modules/nextcloud/deployment.nix
      ];

      networking.hostName = "localacelpb.com";

      environment.systemPackages = [ pkgs.vim ];

      services.nextcloud.dbPassword = "bobisgreat";
      services.nextcloud.adminPassword = "bobisgreat";

      services.nginx.virtualHosts."cloud.${config.networking.hostName}" = {
        sslCertificate = pkgs.writeText "sslCertificate" (builtins.readFile ./selfsigned.crt);
        sslCertificateKey = pkgs.writeText "sslCertificate" (builtins.readFile ./selfsigned.key);
      };

      services.nginx.virtualHosts."${config.networking.hostName}" = {
        sslCertificate = pkgs.writeText "sslCertificate" (builtins.readFile ./selfsigned.crt);
        sslCertificateKey = pkgs.writeText "sslCertificate" (builtins.readFile ./selfsigned.key);
      };
    };
}
