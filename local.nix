{
  acelpb =
    { config, lib, pkgs, ... }:
    {
      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 2048;
      deployment.virtualbox.headless = true;

      imports = [ 
        ./acelpb.nix 
        ./nextcloud/deployment.nix
      ];

      networking.hostName = "localacelpb.com";

      environment.systemPackages = [ pkgs.vim ];

      services.nginx.virtualHosts."cloud.${config.networking.hostName}" = {
        sslCertificate = pkgs.writeText "sslCertificate" (builtins.readFile ./local/selfsigned.crt);
        sslCertificateKey = pkgs.writeText "sslCertificate" (builtins.readFile ./local/selfsigned.key);
      };

      services.nginx.virtualHosts."${config.networking.hostName}" = {
        sslCertificate = pkgs.writeText "sslCertificate" (builtins.readFile ./local/selfsigned.crt);
        sslCertificateKey = pkgs.writeText "sslCertificate" (builtins.readFile ./local/selfsigned.key);
      };
    };
}
