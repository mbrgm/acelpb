# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
{
  imports =
  [ # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
    ./acelpb.nix
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda";

  # Define your hostname.
  networking.hostName = "ns358417";
  networking.hostId = "385cabe4";

  # IPv4 settings
  networking.interfaces.eth0.ip4 = [
    { address = "91.121.89.48";
      prefixLength = 24; } ];
  networking.defaultGateway = "91.121.89.254";
  networking.nameservers = [ "213.186.33.99" ];

  # IPv6 settings
  networking.localCommands =
    ''
      ip -6 addr add 2001:41D0:1:8E30::/64 dev eth0
      ip -6 route add 2001:41D0:1:8Eff:ff:ff:ff:ff dev eth0
      ip -6 route add default via 2001:41D0:1:8Eff:ff:ff:ff:ff
    '';
}
