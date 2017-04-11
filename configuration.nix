# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, pkgs, ... }:
let
  myCfg = builtins.fromJSON (builtins.readFile ./config/private.json);
in
{
  imports =
  [ # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
    ./acelpb.nix
  ];

  acelpb.owncloud.enable = true;
  acelpb.owncloud.hostname = "owncloud.${myCfg.hostname}";
  acelpb.owncloud.forceSSL = true;

  services.nginx.virtualHosts = myCfg.virtualHosts;

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda";

  # Define your hostname.
  networking.hostName = "acelpb.com";
  networking.hostId = "385cabe4";

  # IP settings
  networking.interfaces.enp3s0 = {
    ip4 = [
      {
        address = "91.121.89.48";
        prefixLength = 24;
      }
    ];
    ip6 = [
      {
        address = "2001:41D0:1:8E30::";
        prefixLength = 64;
      }
    ];
  };
  networking.defaultGateway = "91.121.89.254";
  networking.defaultGateway6 = "2001:41D0:1:8Eff:ff:ff:ff:ff";
  networking.nameservers = [ "213.186.33.99" ];
}
