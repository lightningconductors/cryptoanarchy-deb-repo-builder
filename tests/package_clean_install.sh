#!/bin/bash

set -e

test_dir="`dirname "$0"`"
pkg_dir="$1"
package="$2"

. "$test_dir/common.sh"

package_type="${package_type["$package"]}"

# selfhost-clearnet-related options are needed several times, so we needed
# to init them at the beginning of each run due to purge being at the end.
sudo debconf-set-selections < "$test_data_dir/configuration"
# Detect Qubes and redirect paths with big files to /rw
if [ -d /rw -a -e /etc/qubes ];
then
	sudo debconf-set-selections < "$test_data_dir/qubes-configuration"
fi
sudo debconf-set-selections < "$test_data_dir/configuration"
echo "Installing package $package" >&2
sudo apt install -y "$package"
echo "Checking package $package" >&2
check "$package" "$package_type" "after_install"
echo "Reinstalling package $package" >&2
sudo apt reinstall -y "$package"
echo "Checking package $package" >&2
check "$package" "$package_type" "after_install"
echo "Removing package $package" >&2
sudo apt remove -y "$package" ${remove_depends["$package"]}
echo "Checking package $package" >&2
check "$package" "$package_type" "after_remove"
echo "Purging package $package" >&2
sudo apt purge -y "$package" ${remove_depends["$package"]}
# We need to remove content of home dir, but not the dir itself
sudo rm -rf "/var/lib/$package"/*
# Disable connections after bitcoin-mainnet was tested
# in order to avoid fetching blocks during testing.
if [ "$package" = "bitcoin-mainnet" ];
then
	# The directory is removed after purge, so we recreate it
	# Next purges will complain but work anyway.
	sudo mkdir -p /etc/bitcoin-mainnet/conf.d
	echo 'noconect=1' | sudo tee /etc/bitcoin-mainnet/conf.d/noconnect >/dev/null
fi
