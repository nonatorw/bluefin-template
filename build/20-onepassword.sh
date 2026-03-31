#!/usr/bin/env bash

set -oue pipefail

###############################################################################
# 1Password CLI + GUI Installation
###############################################################################
# Uses the official BlueBuild bling installer for 1Password, which correctly
# handles all permissions, groups, polkit policies, and the /opt symlink issue
# on bootc/ostree immutable systems.
#
# Source: https://github.com/blue-build/modules/blob/main/modules/bling/installers/1password.sh
# Reference: https://blue-build.org/reference/modules/bling/
###############################################################################

echo "::group:: Install 1Password CLI + GUI"

# Download and run the official BlueBuild bling installer for 1Password.
# This installer correctly handles:
#   - RPM installation from official AgileBits repository
#   - /opt symlink fix (optfix) for bootc/ostree systems
#   - onepassword group creation with correct GID
#   - chrome-sandbox setuid permissions
#   - BrowserSupport binary permissions (required for CLI integration)
#   - polkit policy installation (required for system auth / fingerprint)
#   - /etc/1password/custom_allowed_browsers
#   - tmpfiles.d rule for /var/opt/1Password symlink at runtime

curl -fLsS --retry 5 \
    https://raw.githubusercontent.com/blue-build/modules/main/modules/bling/installers/1password.sh \
    | bash

echo "1Password CLI + GUI installed successfully"
echo "::endgroup::"
