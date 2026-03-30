#!/usr/bin/env bash

set -oue pipefail

###############################################################################
# Third-Party Applications
###############################################################################

### Firefox Developer Edition via official Mozilla tarball
echo "::group:: Install Firefox Developer Edition"

curl -L \
    --output /tmp/firefox-devedition.tar.xz \
    "https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US"

file /tmp/firefox-devedition.tar.xz

tar -xJf /tmp/firefox-devedition.tar.xz -C /usr/lib
mv /usr/lib/firefox /usr/lib/firefox-developer-edition

ln -sf /usr/lib/firefox-developer-edition/firefox /usr/bin/firefox-developer-edition

cat > /usr/lib/tmpfiles.d/firefox-developer-edition.conf << 'TMPFILES'
L  /var/opt/firefox-developer-edition  -  -  -  -  /usr/lib/firefox-developer-edition
TMPFILES

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

# OPTFIX: DroidCam installs to /opt/droidcam-obs-client AND /usr/local/bin/droidcam
# Both /opt (-> /var/opt) and /usr/local (-> /var/usrlocal) are symlinks to /var
# in bootc systems, and /var is NOT writable during container builds.
# We replace both symlinks with real directories, install, move files to immutable
# paths under /usr, then restore the symlinks.

# Fix /opt
rm -f /opt
mkdir -p /opt

# Fix /usr/local
rm -f /usr/local
mkdir -p /usr/local/bin

dnf5 install -y "https://droidcam.app/go/droidCam.client.setup.rpm"

# Move /opt/droidcam-obs-client to /usr/lib
if [ -d /opt/droidcam-obs-client ]; then
    mkdir -p /usr/lib/droidcam-obs-client
    cp -a /opt/droidcam-obs-client/. /usr/lib/droidcam-obs-client/
fi

# Move /usr/local/bin/droidcam to /usr/bin
if [ -f /usr/local/bin/droidcam ]; then
    cp -a /usr/local/bin/droidcam /usr/bin/droidcam
fi

# Restore /opt as symlink to /var/opt
rm -rf /opt
ln -s /var/opt /opt

# Restore /usr/local as symlink to /var/usrlocal
rm -rf /usr/local
ln -s /var/usrlocal /usr/local

# tmpfiles.d rule to recreate /var/opt/droidcam-obs-client at runtime
cat > /usr/lib/tmpfiles.d/droidcam.conf << 'TMPFILES'
L  /var/opt/droidcam-obs-client  -  -  -  -  /usr/lib/droidcam-obs-client
TMPFILES

dnf5 install -y v4l2loopback

cat > /etc/modprobe.d/v4l2loopback.conf << 'MODPROBE'
options v4l2loopback exclusive_caps=1 card_label="DroidCam" devices=1
MODPROBE

echo "v4l2loopback" > /etc/modules-load.d/v4l2loopback.conf

echo "DroidCam installed successfully"
echo "::endgroup::"
