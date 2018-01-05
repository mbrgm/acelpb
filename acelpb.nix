# Configuration file for acelpb.nix
{ config, pkgs, ... }:
{

  imports =
    [
      <nixpkgs/nixos/modules/profiles/headless.nix>
      ./modules/nextcloud
      ./modules/normandy.nix
      ./modules/jupyter.nix
    ];

  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [
    22 # SSH
    80 # HTTP
    389 # LDAP
    443 # HTTPS
  ];

  programs.bash.enableCompletion = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  services.nginx.enable = true;
  services.nextcloud.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql96;
  };
}
