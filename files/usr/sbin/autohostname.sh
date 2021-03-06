#!/bin/bash
# autohostname.sh: Ensure a unique hostname via root disk serial numbers
# Intended for:
# - Debian boxen
# - USB stick root devices
# - Puppet managed devices (/var/lib/puppet will be recreated)
# - SSH server enabled (ssh host keys will be recreated)
# - Root on LVM (Root device will be pulled from pvs)
# - Domain name will not change
#
# ARGUMENTS:
# $1: Hostname Prefix
# $2: Domain name
# $3: vgs search string

mapfile="/etc/rootdev_hostname_map"

# Check arguments
if [ -z "$1" ]; then
    echo "autohostname: ERROR: Hostname prefix required"
    exit 1
fi
if [ -z "$2" ]; then
    echo "autohostname: ERROR: Domain name required"
    exit 1
fi
if [ -z "$3" ]; then
    echo "autohostname: ERROR: vgs search string required"
    exit 1
fi

# Get root device
rootDev=`pvs | grep "$3" | awk '{print $1}' | sed -e 's|[0-9]$||' -e 's|/dev/||'`
if [ -z $(echo "$rootDev" | grep "^[a-z]\+$" ) ]; then
    echo "autohostname: ERROR: Error determining root device. Got: \"${rootDev}\""
    exit 1
fi

# Get serial number
devID=`ls /dev/disk/by-id/ -l | grep "$rootDev$" | awk '{print $9}'`
if [ -z $devID ]; then
    echo "autohostname: ERROR: Unable to determine root device ID"
    exit 1
fi

# Read previous mapping
if [ -f $mapfile ]; then
    oldDevID=`grep -v "^#" $mapfile`
    if [ $(echo "$oldDevID" | wc -l) -ne 1 ]; then
	echo "autohostname: ERROR: Parse error on $mapfile"
	exit 1
    fi

    if [ "$devID" == "$oldDevID" ]; then
	echo "autohostname: Hostname OK"
	exit 0
    fi
fi

echo "autohostname: Current hostname does not match mapping or mapping missing."
echo "autohostname: WARNING: CHANGING HOSTNAME."

# Stop Puppet & sshd
/etc/init.d/puppet stop 2>/dev/null /dev/null
/etc/init.d/ssh stop 2>/dev/null /dev/null

/etc/init.d/puppet status 2>/dev/null /dev/null
if [ $? -eq 0 ]; then
    echo "autohostname: ERROR: Puppet failed to stop"
    exit 1
fi
/etc/init.d/ssh status 2>/dev/null /dev/null
if [ $? -eq 0 ]; then
    echo "autohostname: ERROR: SSH failed to stop"
    exit 1
fi

# Clean puppet
rm /var/lib/puppet -rf

# Clean SSH
rm /etc/ssh/ssh_host_* -f

# Change hostname
newHostname="$1-$(uuidgen -t).$2"
echo "autohostname: New hostname: $newHostname"

# Overwrite /etc/hostname and /etc/mailname
echo $newHostname > /etc/hostname
echo $newHostname > /etc/mailname

# Correct other files with sed
sed -e "s|$(hostname -f)|${newHostname}|g" /etc/hosts -i

# Motd will be fixed by puppet, not fiddling with LVM
# No other files should (*should*) need mods.

# /END CONFIG CHANGES

# Change the running hostname
hostname $newHostname

# Write mapping
echo "# autohostname USB Stick ID mapping file" > $mapfile
echo "# This is not a standard config file." >> $mapfile
echo "$devID" >> $mapfile

# Reconfigure ssh / generate new keys
dpkg-reconfigure openssh-server

# Wipe histories
for f in $(ls /home/*/.bash_history /root/.bash_history 2>/dev/null); do echo > $f; done

# Reboot to ensure X and friends (slim, dbus, consolekit, policykit) are happy
shutdown -r now "Reboot for hostname change"
