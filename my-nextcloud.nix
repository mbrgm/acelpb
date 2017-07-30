with import <nixpkgs> {}; # bring all of Nixpkgs into scope

stdenv.mkDerivation rec {
  name = "my-nextcloud";
  src = pkgs.nextcloud;

  installPhase =
    ''
      mkdir -p $out
      find . -maxdepth 1 -execdir cp -r '{}' $out \;

      rm -rf $out/data;
      ln -s /var/lib/nextcloud/data $out/data;

      mv $out/apps $out/immutable_apps
      ln -s /var/lib/nextcloud/apps $out/apps;

      rm -rf $out/config
      ln -s /var/lib/nextcloud/config $out/config;
    '';
}
