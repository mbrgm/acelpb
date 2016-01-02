# Configuration file for acelpb.nix
{ config, pkgs, ... }:
let
  myCfg = builtins.fromJSON (builtins.readFile ./private/config.json);
in
{
  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 389 ];

  # Select internationalisation properties.
  i18n.defaultLocale = "fr_BE.UTF-8";
  time.timeZone = "Europe/Brussels";

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    bashCompletion
    php
    nodejs
    python
    git
    vim
    sbt
    wget
  ];

  services = {

    phd.enable = true;

    mysql = {
      enable = true;
      package = pkgs.mariadb;
      extraOptions = "sql_mode=STRICT_ALL_TABLES";
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql94;
    };

    openldap = {
      enable = true;
      extraConfig =
        ''
          ##########
          # Basics #
          ##########
          include ${pkgs.openldap}/etc/openldap/schema/core.schema
          include ${pkgs.openldap}/etc/openldap/schema/cosine.schema
          include ${pkgs.openldap}/etc/openldap/schema/inetorgperson.schema
          include ${pkgs.openldap}/etc/openldap/schema/nis.schema

          ##########################
          # Database Configuration #
          ##########################
          database bdb
          suffix dc=acelpb,dc=com
          rootdn cn=root,dc=acelpb,dc=com

          # NOTE: change after first start
          rootpw ${myCfg.ldap.password}

          directory /var/db/openldap
      '';
    };

    jenkins = {
      enable = true;
      port = 2711;
      extraOptions = [ "--prefix=/jenkins" "--httpListenAddress=localhost" ];
    };

    gitlab = {
      enable = true;
      databasePassword = "some_password";
    };

    httpd = {
      enable = true;
      adminAddr="a.borsu@gmail.com";
      enablePHP = true;

      virtualHosts = [
        { # Forces all connections to https
          extraConfig = ''
            RewriteEngine On
            RewriteCond %{HTTPS} off
            RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
          '';
        }
        { # hostname acelpb.com with document root and owncloud
          hostName = myCfg.domain;
          documentRoot = "/var/www/root";
          extraConfig =
            ''
              Alias /jcm /var/www/jcm

              <Directory /var/www/jcm>
                Options Indexes FollowSymLinks
                AllowOverride FileInfo
                Require all granted
              </Directory>


              ProxyPass         /jenkins  http://localhost:2711/jenkins nocanon
              ProxyPassReverse  /jenkins  http://localhost:2711/jenkins
              ProxyRequests     Off
              AllowEncodedSlashes NoDecode

              # Local reverse proxy authorization override
              # Most unix distribution deny proxy by default (ie /etc/apache2/mods-enabled/proxy.conf in Ubuntu)
              <Proxy http://localhost:2711/jenkins*>
                Order deny,allow
                Allow from all
              </Proxy>
            '';

          extraSubservices = [
            {
              trustedDomain = myCfg.domain;
              urlPrefix = "/owncloud";
              serviceType = "owncloud";
              dbUser = myCfg.owncloud.dbUser;
              dbPassword = myCfg.owncloud.dbPassword;
              adminUser = myCfg.owncloud.adminUser;
              adminPassword = myCfg.owncloud.adminPassword;
            }
          ];
          # Regarding server certificates and keys, nix store is readable by anyone
          # So if I put the name in a public config any user able to run a simple command
          # on the server could get a copy of the key.
          # On the other hand, my local instances all run locally and I destroy and create
          # them multiple time a day so copying the certificates by hand would get tiresome.
          sslServerCert = if myCfg.domain == "acelpb.local"
            then builtins.toFile "ssl.crt" (builtins.readFile ./private/server.crt)
            else myCfg.ssl.www.crt;
      	  sslServerKey = if myCfg.domain == "acelpb.local"
            then builtins.toFile "ssl.key" (builtins.readFile ./private/server.key)
            else myCfg.ssl.www.key;
          sslServerChain = if myCfg.domain == "acelpb.local"
            then null
            else myCfg.ssl.www.ca;
          enableSSL = true;
        }
        {
          hostName = "phabricator." + myCfg.domain;
          extraSubservices = [{serviceType = "phabricator";}];
          sslServerCert = if myCfg.domain == "acelpb.local"
            then builtins.toFile "ssl.crt" (builtins.readFile ./private/server.crt)
            else myCfg.ssl.phabricator.crt;
          sslServerKey = if myCfg.domain == "acelpb.local"
            then builtins.toFile "ssl.key" (builtins.readFile ./private/server.key)
            else myCfg.ssl.phabricator.key;
          sslServerChain = if myCfg.domain == "acelpb.local"
            then null
            else myCfg.ssl.phabricator.ca;
          enableSSL = true;
        }
        {
          hostName = "gitlab." + myCfg.domain;
          extraConfig = ''
            # prevent a forward proxy!
            ProxyRequests off

            # User-Agent / browser identification is used from the original client
            ProxyVia Off
            ProxyPreserveHost On

            <Proxy *>
            Order deny,allow
            Allow from all
            </Proxy>

            ProxyPass / http://127.0.0.1:8080/
            ProxyPassReverse / http://127.0.0.1:8080/
          '';
          sslServerCert = if myCfg.domain == "acelpb.local"
            then builtins.toFile "ssl.crt" (builtins.readFile ./private/server.crt)
            else myCfg.ssl.phabricator.crt;
          sslServerKey = if myCfg.domain == "acelpb.local"
            then builtins.toFile "ssl.key" (builtins.readFile ./private/server.key)
            else myCfg.ssl.phabricator.key;
          sslServerChain = if myCfg.domain == "acelpb.local"
            then null
            else myCfg.ssl.phabricator.ca;
          enableSSL = true;
        }
      ];
    };

    openssh.enable = true;

    xserver.enable = false;

  };

  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.aborsu = {
    description = "Augustin Borsu";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDT6nGess3TiV7KCZqCzv7wqny1GYsH9bkiT6Vae2Xo8I0YgvkqD6C/QszEk28lu7CMsm2bb8bDkYKm6Ce8jTin+hyobVvlxC5fAYZK8oE4AKn1rHkDqq1wnJwTRIrB97Nc2077BHAv2OLh5G2A/uazkIWxcoIBJNne9fFXY8B98DoB4WsDtBxj7OFnDIm27qX2VtScrr7U95SGjKN6F6MUyFEcFu9GhkXLs8BS/G8oVfSSmHFTBpIeNQ69BX7NXb+mWP98ouD4yGsRSiKZHdSwjVWI1JU4MO0tGkRAZXY2p0vacp+ePh6r0ESHbVUazX4Vof7p1i35VlIg850C9iAq6xhx3b59lYVk6AyAhfj0lujz10+00EkHy6l9BmtzBV1mFmTJpMPFQQ00Hup92ihMyGNglgPs23s3lR8iLjQ7gDpNohHmFKBFSG2Jp2tEhnfuH3tz3NWn4pXPyIUWs5znRb9Sup7/XoRtelZrSEai/EUPeP5RysYMsxiRoms47rD8FWTE0hQFUrHjQzk+RGUd/OCBv3LPR6wiwfRmdIJnNg6yDahNsRiJ3bCqtwjRkdpZ1ezLAzgwNVaNRWq4EEHMfeQ7Oud7yjgdqhb0vvAy5J4ZSHM05+77sNQoAPVEYlEhYJwyfukDMprkImypVhdOplkGaqTxMDvPY46ipGjK5Q== aborsu@mbpro-gus-Ven 16 oct 2015 10:13:03 CEST" ];
  };

  users.extraUsers.jcm = {
    isNormalUser = true;
    description = "Jean-Christophe Maigrot";
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKjZS/Z37B0kZ1jfWXNQGEsNU9LM2Y2YcghHqFiO5IuWSu+XzFoRdeeFfcsfF/j5uQbWy+23z2CvuivsdNAdqS4Gl7X+wAg9pG9A+h9BRWEjGN/Llpq0NOPeiFSgLOxFuu4VOU6QzVPpgSLLWqM+av3Ib8q5UHCE49CPIcptwnOFmSQtvk6nDtbZpb9WA+MnL+xOp1P1nXu9JbpUUvCcZuqYWSrg+OMEkFv9ujTzK9uEnUMgQq4N7o4swUpXcs1dKt9Ev96Pr+GlSmcr567l+Ach2nX6+4l01ygzCCzEEzyodFT8qf8xGw3Aak+38Bu/qcqtHXNxPQ4IQgFyhyiyFl jcm@acelpb-" ];
  };

}


