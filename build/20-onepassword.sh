#!/usr/bin/env bash

set -oue pipefail

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

# Diagnose what exists at /opt/1Password before attempting install
echo "--- RPM packages containing 1password ---"
rpm -qa | grep -i 1password || echo "(none found)"
echo "--- Contents of /opt/1Password (if exists) ---"
ls -la /opt/1Password/ 2>/dev/null || echo "(directory does not exist)"
echo "--- /opt contents ---"
ls -la /opt/ 2>/dev/null || echo "(empty)"

echo "::endgroup::"
