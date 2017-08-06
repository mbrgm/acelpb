# Configuration file for acelpb.nix
{ config, pkgs, ... }:
{

  imports =
    [
      <nixpkgs/nixos/modules/profiles/headless.nix>
      ./nextcloud.nix
      ./normandy.nix
    ];

  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [ 22 80 389 443 ];
  
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Enable the openldap daemon
  # services.openldap.enable = true;
  # services.openldap.configDir = "/var/db/slapd.d";

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  services.nginx.enable = true;
  services.nextcloud.enable = true;
  
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql96;
  };
}
