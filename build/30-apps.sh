#!/usr/bin/env bash

set -oue pipefail

###############################################################################
# Third-Party Applications
###############################################################################

### Firefox Developer Edition via official Mozilla tarball
echo "::group:: Install Firefox Developer Edition"

# Download the latest Firefox Developer Edition tarball from Mozilla
# -L follows redirects (required — Mozilla URL redirects to CDN)
curl -L \
    --output /tmp/firefox-devedition.tar.xz \
    "https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US"

# Verify the file type
file /tmp/firefox-devedition.tar.xz

# Extract directly to /usr/lib (always writable during build — /opt is a
# symlink to /var/opt which is NOT writable during bootc container builds)
tar -xJf /tmp/firefox-devedition.tar.xz -C /usr/lib
mv /usr/lib/firefox /usr/lib/firefox-developer-edition


# Create symlink in /usr/bin for CLI access
ln -sf /usr/lib/firefox-developer-edition/firefox /usr/bin/firefox-developer-edition

# Create a tmpfiles.d rule to expose the app at /opt/firefox-developer-edition
# at runtime (for apps/scripts that expect it under /opt)
cat > /usr/lib/tmpfiles.d/firefox-developer-edition.conf << 'TMPFILES'
L  /var/opt/firefox-developer-edition  -  -  -  -  /usr/lib/firefox-developer-edition
TMPFILES

# Create .desktop file so it appears in the GNOME app launcher
cat > /usr/share/applications/firefox-developer-edition.desktop << 'DESKTOP'
[Desktop Entry]
Name=Firefox Developer Edition
GenericName=Web Browser
Comment=Firefox Developer Edition Web Browser
Exec=/usr/lib/firefox-developer-edition/firefox %u
Icon=/usr/lib/firefox-developer-edition/browser/chrome/icons/default/default128.png
Terminal=false
Type=Application
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;x-scheme-handler/http;x-scheme-handler/https;
Categories=Network;WebBrowser;
StartupNotify=true
StartupWMClass=Firefox Developer Edition
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=New Window
Exec=/usr/lib/firefox-developer-edition/firefox --new-window

[Desktop Action new-private-window]
Name=New Private Window
Exec=/usr/lib/firefox-developer-edition/firefox --private-window
DESKTOP

# Clean up temp file
rm -f /tmp/firefox-devedition.tar.xz

echo "Firefox Developer Edition installed to /usr/lib/firefox-developer-edition"
echo "::endgroup::"

### LinuxToys via Fedora COPR
echo "::group:: Install LinuxToys"

curl -fsSL "https://copr.fedorainfracloud.org/coprs/psygreg/linuxtoys/repo/fedora-$(rpm -E %fedora)/psygreg-linuxtoys-fedora-$(rpm -E %fedora).repo" \
    --output /etc/yum.repos.d/psygreg-linuxtoys.repo

dnf5 install -y linuxtoys

rm -f /etc/yum.repos.d/psygreg-linuxtoys.repo

echo "LinuxToys installed successfully"
echo "::endgroup::"

### DroidCam Client via official RPM
echo "::group:: Install DroidCam Client"

dnf5 install -y "https://droidcam.app/go/droidCam.client.setup.rpm"

dnf5 install -y v4l2loopback

cat > /etc/modprobe.d/v4l2loopback.conf << 'MODPROBE'
options v4l2loopback exclusive_caps=1 card_label="DroidCam" devices=1
MODPROBE

echo "v4l2loopback" > /etc/modules-load.d/v4l2loopback.conf

echo "DroidCam installed successfully"
echo "::endgroup::"
