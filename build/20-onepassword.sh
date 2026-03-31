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
# /var/opt/1Password/ — this fails with "mkdir failed - File exists".
#
# THE FIX:
# 1. Remove the /opt symlink and create a real /opt directory
# 2. Install the RPM (now writes to real /opt)
# 3. Run after-install.sh WHILE /opt/1Password/ still exists
# 4. Move files to /usr/lib/1password (immutable layer)
# 5. Restore /opt as symlink to /var/opt
# 6. Create tmpfiles.d rule to recreate /var/opt/1Password at runtime
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

# OPTFIX step 1: Replace /opt symlink with a real directory
rm -f /opt
mkdir -p /opt

# Install both packages
dnf5 install -y 1password 1password-cli

# OPTFIX step 2: Run after-install.sh BEFORE moving files
# The script expects files at /opt/1Password/ — which exists at this point
echo ">>> Running 1Password post-install script..."
cd /opt/1Password
sh /opt/1Password/after-install.sh
cd /

# OPTFIX step 3: Move installed files to /usr/lib (immutable layer)
mkdir -p /usr/lib/1password
cp -a /opt/1Password/. /usr/lib/1password/

# OPTFIX step 4: Restore /opt as symlink to /var/opt
rm -rf /opt
ln -s /var/opt /opt

# OPTFIX step 5: tmpfiles.d rule to recreate /var/opt/1Password at runtime
cat > /usr/lib/tmpfiles.d/1password.conf << 'TMPFILES'
L  /var/opt/1Password  -  -  -  -  /usr/lib/1password
TMPFILES

# Ensure the onepassword group exists
getent group onepassword || groupadd onepassword

# Fix permissions on BrowserSupport binary
chgrp onepassword /usr/lib/1password/1Password-BrowserSupport
chmod g+s /usr/lib/1password/1Password-BrowserSupport

# Fix chrome-sandbox setuid
chmod 4755 /usr/lib/1password/chrome-sandbox

rm -f /etc/yum.repos.d/1password.repo

echo "1Password CLI + GUI installed successfully"
echo "::endgroup::"
