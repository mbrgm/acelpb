# Owncloud deployment
#
# Only use with nixops. 
# This module contains scripts to deploy secrets and configure nextcloud. 
{ config, lib, pkgs, ... }:

with lib;

{

  options.services.nextcloud = {
    passwordsalt = {
      type = types.str;
      default = "";
    };
  };

  config = {
    deployment.keys."secret.config.php" = {
      destDir = "${config.services.nextcloud.installPrefix}/config";
      group = config.services.nextcloud.phpfpm.group;
      permissions = "0600";
      text = ''
        <?php
        $CONFIG = array (
          'passwordsalt' => 'Zv1BzPvi6ErZNzPg0LaWZ7o/wYw3vv',
          'secret' => 'EUT3nYxYgrP7OECDzcP0GVJxgZ/frX0Ypxmg8K6oNeBpEGJr',
          'dbtype' => 'sqlite3',
        );
      '';
      user = config.services.nextcloud.phpfpm.user;
    };
  };  
}
