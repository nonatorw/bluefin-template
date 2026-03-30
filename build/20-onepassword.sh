#!/usr/bin/env bash

set -oue pipefail

###############################################################################
# 1Password CLI + GUI Installation
###############################################################################

echo "::group:: Install 1Password CLI + GUI"

# Import GPG key
rpm --import https://downloads.1password.com/linux/keys/1password.asc

# Add 1Password RPM repository
cat > /etc/yum.repos.d/1password.repo << 'REPO'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
REPO

# Use --setopt=tsflags=noscripts,nodocs to skip post-install scripts that may
# conflict, and --allowerasing to replace any conflicting packages.
# If already installed (e.g. from cache layer), reinstall; otherwise install.
dnf5 install -y --allowerasing 1password-cli

# For the GUI, use rpm directly with --replacepkgs to handle pre-existing files
# in the overlay filesystem from buildah cache layers
dnf5 download --destdir=/tmp/1password-rpms 1password
rpm -Uvh --replacepkgs --replacefiles /tmp/1password-rpms/1password*.rpm
rm -rf /tmp/1password-rpms

rm -f /etc/yum.repos.d/1password.repo

echo "1Password CLI + GUI installed successfully"
echo "::endgroup::"
