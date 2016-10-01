{ config, pkgs, ... }:
{
  services = {
    jenkins = {
      enable = true;
      port = 2711;
      listenAddress = "localhost";
      extraGroups = [ "docker" ];
      packages = [
        pkgs.coreutils
        pkgs.stdenv
        pkgs.git
        pkgs.jdk
        config.programs.ssh.package
        pkgs.nix
        pkgs.sbt
        pkgs.maven
        pkgs.docker
        pkgs.pythonPackages.docker_compose
        pkgs.bash
      ];
    };
  };
}


