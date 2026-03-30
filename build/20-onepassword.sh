#!/usr/bin/env bash

set -oue pipefail

###############################################################################
# 1Password CLI + GUI Installation
###############################################################################
# Installs both the 1Password GUI and the 1Password CLI from the official
# AgileBits RPM repository.
#
# WHY THE OPTFIX IS NEEDED:
# In bootc/ostree systems, /opt is a symlink to /var/opt. During container
# image builds, /var is not writable (it's an overlay mounted at runtime).
# The 1Password RPM tries to install to /opt/1Password/ which resolves to
# /var/opt/1Password/ — this fails with "mkdir failed - File exists" because
# the overlayfs cannot write to /var during build time.
#
# The fix (known as "optfix" in the Universal Blue ecosystem) is to:
# 1. Remove the /opt symlink temporarily
# 2. Create a real /opt directory
# 3. Install the RPM (now writes to real /opt)
# 4. Move the installed files to /usr/lib/1password (which IS writable)
# 5. Restore /opt as a symlink to /var/opt
# 6. Create a symlink /var/opt/1Password -> /usr/lib/1password at runtime
#    via a tmpfiles.d rule so the app can find its files at /opt/1Password/
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

# OPTFIX step 1: Replace /opt symlink with a real directory so RPM can install
rm -f /opt
mkdir -p /opt

# Install both packages
dnf5 install -y 1password 1password-cli

# OPTFIX step 2: Move installed files out of /opt into /usr/lib (immutable layer)
mkdir -p /usr/lib/1password
cp -a /opt/1Password/. /usr/lib/1password/

# OPTFIX step 3: Restore /opt as symlink to /var/opt (bootc convention)
rm -rf /opt
ln -s /var/opt /opt

# OPTFIX step 4: Create a tmpfiles.d rule to recreate /var/opt/1Password ->
# /usr/lib/1password on every boot, so the app finds its files at /opt/1Password/
cat > /usr/lib/tmpfiles.d/1password.conf << 'TMPFILES'
L  /var/opt/1Password  -  -  -  -  /usr/lib/1password
TMPFILES

rm -f /etc/yum.repos.d/1password.repo

echo "1Password CLI + GUI installed successfully"
echo "::endgroup::"
