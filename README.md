OpenSwan
========
Configure an OpenSwan VPN


Usage
-----

To use the cookbook, create the following entries in your `node.json`:

    {
      "openswan": {
        "vpn_ip_range": "xxx.xxx.xxx.2-xxx.xxx.xxx.254",
        "vpn_local_ip": "xxx.xxx.xxx.1",
        "subnet_cidr": "xxx.xxx.xxx.0/24",
        "ipsec_psk": "some very long psk",
        "users": [
          {"username": "USER", "password": "PASS"}
        ]
      }
    }

VPN Setup
---------

First, set `ipsec_psk` to a very long random string.

Then, for each road warrior, set the `username` set to the machine name.
Generate a very long random string for its `password`.

If you have a Rails app and need an example of a very long random string, run:

    $ rake secret

OnePassword also generates very long random strings.
