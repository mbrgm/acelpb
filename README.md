# Nix configuration files for acelpb.com

Two interesting files here.
configuration.nix (For the actual server deployment.)
local.nix (for testing with nixops)

# Instructions

Need to create a private folder and a config.json file. This config contains access details and I have chosen not to share it for security reasons.
Example config used when testing locally:
```
{
  "ldap": {
    "password": "secret"
  },
  "owncloud": {
    "dbUser": "owncloud",
    "dbPassword": "owncloud",
    "adminUser": "aborsu",
    "adminPassword": "secret"
  },
  "ssl": {
    "www": "/someSSLPath",
    "phabricator": "/someSSLPath"
  },
  "domain": "acelpb.local"
}
```

For server deployment you will need to specify real path in ssl.www and change the domain to whatever you want.

For testing using nixops you need to add a (self-signed) server.key and server.crt in the ./private folder you have created.
Then create and deploy using the following commands:
```
nixops create -d acelpb local.nix
nixops deploy -d local
```

Additionnaly you should add this line to your /etc/hosts file:
```
192.168.56.10  acelpb.local phabricator.acelpb.local gitlab.acelpb.local
```

#TESTS
[ssl test](https://www.ssllabs.com/ssltest/analyze.html?d=acelpb.com&latest)
[email test](http://emailsecuritygrader.com/)

Have fun with NixOS

