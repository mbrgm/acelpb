{
  acelpb =
    { config, lib, pkgs, ... }:
    {

      deployment.targetEnv = "virtualbox";
      deployment.virtualbox.memorySize = 2048;
      deployment.virtualbox.headless = true;

      imports = [ 
        ./acelpb.nix 
        ./local-secret.nix 
      ];

      networking.hostName = "localacelpb.com";

      environment.systemPackages = [ pkgs.vim ];

      services.nginx.virtualHosts."cloud.${config.networking.hostName}" = {
        sslCertificate = pkgs.writeText "sslCertificate" ''
          This is a certificate;
        '';
        sslCertificateKey = pkgs.writeText "sslCertificateKey" ''
          This is a certificate;
        '';
      };
    };
}
