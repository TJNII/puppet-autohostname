autohostname
============

This module installs a script and init script to ensure the system hostname is unique.
Intended for USB stick installs that will be cloned with dd.  Uses the disk id
(via /dev/disk/by-id) to determine if the hostname needs to be altered.
Uses a prefixed UUID for the hostname.

Requirements
============
Only supports Debian at this time.  Will fail, possibly silently, on other distros.
Intended to be run on a install using slim.

Changes Made
============

* Replaces /etc/hostname
* Replaces /etc/mailname
* Updates /etc/hosts via sed regex
* Removes /var/lib/puppet to force puppet cert regeneration
* Removes and regenerates sshd keys
* Reboots server on change to ensure change is fully propagated and to ensure slim/dbus/consolekit/policykit react properly.