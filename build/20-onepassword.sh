#!/usr/bin/env bash

set -oue pipefail

###############################################################################
# 1Password CLI + GUI Installation
###############################################################################
# Installs both the 1Password GUI and the 1Password CLI (op) from the official
# AgileBits RPM repository.
#
# Installing via RPM (instead of Flatpak) is required for:
#   - Browser integration (1Password extension)
#   - Terminal/CLI integration (op command)
#   - SSH agent integration
#
# CONVENTIONS:
# - Always clean up repo files after installation
# - Use dnf5 exclusively (never dnf or yum)
# - Remove repo files to keep the image clean (repos don't work at runtime)
###############################################################################

echo "::group:: Install 1Password CLI"

# Import GPG key
rpm --import https://downloads.1password.com/linux/keys/1password.asc

# Add 1Password RPM repository
cat > /etc/yum.repos.d/1password.repo << 'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

# Install 1Password GUI and CLI
dnf5 install -y 1password 1password-cli

# Clean up repo file (required - repos don't work at runtime in bootc images)
rm -f /etc/yum.repos.d/1password.repo

echo "1Password CLI installed successfully"

echo "::endgroup::"
