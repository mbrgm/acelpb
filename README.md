# Nix configuration files for acelpb.com

acelpb.nix (Main server configuration.)
local.nix (for testing with nixops)
local.nix (for deployment with nixops)

# Instructions

Create and deploy using the following commands:
```
nixops create -d acelpb local.nix
nixops deploy -d local
```
#TESTS
[ssl test](https://www.ssllabs.com/ssltest/analyze.html?d=acelpb.com&latest)
[email test](http://emailsecuritygrader.com/)

Have fun with NixOS
