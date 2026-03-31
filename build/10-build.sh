#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Main Build Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

# Enable nullglob for all glob operations to prevent failures on empty matches
shopt -s nullglob

echo "::group:: Copy Bluefin Config from Common"

# Copy just files from @projectbluefin/common (includes 00-entry.just which imports 60-custom.just)
mkdir -p /usr/share/ublue-os/just/
shopt -s nullglob
cp -r /ctx/oci/common/bluefin/usr/share/ublue-os/just/* /usr/share/ublue-os/just/
shopt -u nullglob

echo "::endgroup::"

echo "::group:: Copy Custom Files"

# Copy Brewfiles to standard location
mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/

# Consolidate Just Files
find /ctx/custom/ujust -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

# Copy Flatpak preinstall files
mkdir -p /etc/flatpak/preinstall.d/
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/

echo "::endgroup::"

echo "::group:: Install System Packages"

dnf5 install -y \
    zsh \
    eza \
    chezmoi \
    git

echo "::endgroup::"

echo "::group:: Set ZSH as Default Shell"

# Make zsh available as a login shell system-wide
grep -qxF '/usr/bin/zsh' /etc/shells || echo '/usr/bin/zsh' >> /etc/shells

# Set zsh as the default shell for new users (via useradd defaults)
sed -i 's|^SHELL=.*|SHELL=/usr/bin/zsh|' /etc/default/useradd || true

echo "::endgroup::"

echo "::group:: System Configuration"

# Enable/disable systemd services
systemctl enable podman.socket



echo "::endgroup::"

echo "::group:: GNOME Default Settings"

# Activate numpad by default on login.
# dconf update cannot run during container build (no D-Bus available).
# Writing the keyfile directly is the correct approach for bootc images.
# On first login, GNOME reads /etc/dconf/db/local.d/ and applies these defaults.
# Write dconf defaults to /etc/dconf/
# These files are created during build and become part of the immutable image
mkdir -p /etc/dconf/db/local.d/
cat > /etc/dconf/db/local.d/01-keyboard << 'DCONF'
[org/gnome/desktop/peripherals/keyboard]
numlock-state=true

[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
binding='<Super>t'
command='ptyxis'
name='Terminal'
DCONF

# Add local db to dconf profile
# Append to existing profile if present, otherwise create it
mkdir -p /etc/dconf/profile/
if [[ -f /etc/dconf/profile/user ]]; then
    grep -q "system-db:local" /etc/dconf/profile/user         || echo "system-db:local" >> /etc/dconf/profile/user
else
    printf "user-db:user
system-db:local
" > /etc/dconf/profile/user
fi

echo "::endgroup::"

echo "::group:: Configure Plymouth"

# Ensure Plymouth graphical boot theme is active.
# Required for the graphical disk unlock prompt (LUKS) to appear at boot.
# The 'bgrt' theme uses the system firmware logo — consistent with Bluefin DX.
plymouth-set-default-theme bgrt

# Regenerate initramfs to embed the Plymouth theme.
# In bootc/OCI images the initramfs must be rebuilt at image build time —
# it cannot be regenerated at runtime on an immutable system.
dracut --regenerate-all --force

echo "::endgroup::"

# Restore default glob behavior
shopt -u nullglob

# Clean up runtime and var directories left by dnf5
# These are flagged by bootc container lint as they should not persist in the image
rm -rf /var/lib/dnf
rm -rf /run/dnf
rm -rf /run/rpm-ostree

echo "Custom build complete!"
