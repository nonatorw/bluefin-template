#!/usr/bin/env bash

set -oue pipefail

###############################################################################
# Third-Party Applications
###############################################################################
# Installs applications that require external repositories or direct downloads
# and cannot be distributed via standard Flatpak/Flathub:
#
#   - Firefox Developer Edition: official Mozilla tarball, installed to /opt
#   - LinuxToys: user-friendly tools collection, via official Fedora COPR
#   - DroidCam Client: use Android phone as webcam, via official RPM
#
# DroidCam also requires the v4l2loopback kernel module for virtual camera
# support. The module is loaded via a modprobe.d configuration file.
#
# CONVENTIONS:
# - Always clean up repo files and temp files after installation
# - Use dnf5 exclusively (never dnf or yum)
# - Remove repo files to keep the image clean (repos don't work at runtime)
###############################################################################

### Firefox Developer Edition via official Mozilla tarball
echo "::group:: Install Firefox Developer Edition"

# Download the latest Firefox Developer Edition tarball from Mozilla
curl -L "https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US" \
    --output /tmp/firefox-devedition.tar.bz2

# Extract to /opt
tar -xjf /tmp/firefox-devedition.tar.bz2 -C /opt
mv /opt/firefox /opt/firefox-developer-edition

# Create symlink for CLI access
ln -sf /opt/firefox-developer-edition/firefox /usr/local/bin/firefox-developer-edition

# Create .desktop file so it appears in the GNOME app launcher
cat > /usr/share/applications/firefox-developer-edition.desktop << 'DESKTOP'
[Desktop Entry]
Name=Firefox Developer Edition
GenericName=Web Browser
Comment=Firefox Developer Edition Web Browser
Exec=/opt/firefox-developer-edition/firefox %u
Icon=/opt/firefox-developer-edition/browser/chrome/icons/default/default128.png
Terminal=false
Type=Application
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;x-scheme-handler/http;x-scheme-handler/https;
Categories=Network;WebBrowser;
StartupNotify=true
StartupWMClass=Firefox Developer Edition
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=New Window
Exec=/opt/firefox-developer-edition/firefox --new-window

[Desktop Action new-private-window]
Name=New Private Window
Exec=/opt/firefox-developer-edition/firefox --private-window
DESKTOP

# Clean up temp file
rm -f /tmp/firefox-devedition.tar.bz2

echo "Firefox Developer Edition installed to /opt/firefox-developer-edition"
echo "::endgroup::"

### LinuxToys via Fedora COPR
echo "::group:: Install LinuxToys"

# Add LinuxToys COPR repository for Atomic/Universal Blue systems
curl -fsSL "https://copr.fedorainfracloud.org/coprs/psygreg/linuxtoys/repo/fedora-$(rpm -E %fedora)/psygreg-linuxtoys-fedora-$(rpm -E %fedora).repo" \
    --output /etc/yum.repos.d/psygreg-linuxtoys.repo

dnf5 install -y linuxtoys

# Clean up repo file (repos don't work at runtime in bootc images)
rm -f /etc/yum.repos.d/psygreg-linuxtoys.repo

echo "LinuxToys installed successfully"
echo "::endgroup::"

### DroidCam Client via official RPM
echo "::group:: Install DroidCam Client"

# Download and install the official DroidCam RPM for Fedora/RHEL
dnf5 install -y "https://droidcam.app/go/droidCam.client.setup.rpm"

# Install v4l2loopback for virtual camera support (from RPM Fusion)
# RPM Fusion free is already available in Bluefin DX
dnf5 install -y v4l2loopback

# Configure v4l2loopback to load at boot with webcam-compatible settings
cat > /etc/modprobe.d/v4l2loopback.conf << 'MODPROBE'
options v4l2loopback exclusive_caps=1 card_label="DroidCam" devices=1
MODPROBE

# Ensure the module is loaded at boot
echo "v4l2loopback" > /etc/modules-load.d/v4l2loopback.conf

echo "DroidCam installed successfully"
echo "::endgroup::"
