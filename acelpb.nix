# Configuration file for acelpb.nix
{ config, pkgs, ... }:
{

  imports =
    [
      <nixpkgs/nixos/modules/profiles/headless.nix>
      ./nextcloud-service.nix
    ];

  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  services.lighttpd = {
    enable = true;
    nextcloud.enable = true;
    # nextcloud.package = (import ./my-nextcloud.nix);
  };
}
