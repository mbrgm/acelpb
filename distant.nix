{
  acelpb =
    { config, lib, pkgs, ... }:
    {

      deployment.targetHost = "91.121.89.48";

      imports =
        [
          <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
          ./acelpb.nix
        ];

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

      boot.extraModulePackages = [ ];
      boot.initrd.availableKernelModules = [ "xhci_hcd" "ahci" ];
      boot.kernelModules = [ "kvm-intel" ];

      # Use the GRUB 2 boot loader.
      boot.loader.grub.enable = true;
      boot.loader.grub.version = 2;
      # Define on which hard drive you want to install Grub.
      boot.loader.grub.device = "/dev/sda";
      
      fileSystems."/" =
        { device = "/dev/disk/by-uuid/cff9a33c-0725-4d79-bb4b-2712afa21b2e";
          fsType = "ext4";
        };

      fileSystems."/var" =
        { device = "/dev/disk/by-uuid/21d9978f-dc8b-4ddf-bd36-48848336e583";
          fsType = "ext4";
        };

      fileSystems."/home" =
        { device = "/dev/disk/by-uuid/bf1efb96-8c05-412a-84a8-6b0068e416fe";
          fsType = "ext4";
        };

      swapDevices = [ ];

      nix.maxJobs = lib.mkDefault 8;
      powerManagement.cpuFreqGovernor = "powersave";

    };
}
