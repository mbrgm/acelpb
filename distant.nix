{
  acelpb =
    { config, lib, pkgs, ... }:
    {

      deployment.targetHost = "91.121.89.48";

      imports =
        [
          <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
          ./acelpb.nix
          ./distant-secret.nix
          ./distant-hardware.nix
        ];

      networking.hostName = "acelpb.com";
      networking.hostId = "385cabe4";

      services.nginx.virtualHosts."cloud.${config.networking.hostName}".enableACME = true;
      services.nginx.virtualHosts."${config.networking.hostName}".enableACME = true;
    };
}