#!/bin/sh
# Install the GNOME Shell extensions the Lorien GNOME setup uses that aren't in the Arch repos:
# Dash to Dock, Blur my Shell and Just Perfection from extensions.gnome.org, then Isle from its
# own installer. Everything goes into ~/.local/share; no root needed. Log out and back in after.
set -e
SHELL_VERSION="$(gnome-shell --version | grep -o '[0-9]*' | head -1)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
# with arguments: only those extensions (UUIDs), e.g. arcmenu@arcmenu.com
UUIDS="${*:-dash-to-dock@micxgx.gmail.com blur-my-shell@aunetx just-perfection-desktop@just-perfection}"
for uuid in $UUIDS; do
    url="$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$SHELL_VERSION" \
        | python3 -I -c 'import json, sys; print(json.load(sys.stdin)["download_url"])')"
    curl -fsSL "https://extensions.gnome.org$url" -o "$WORK/$uuid.zip"
    gnome-extensions install --force "$WORK/$uuid.zip"
    echo "installed $uuid"
done
# Isle, the island in the top bar: its own installer checks the download's checksum
[ $# -gt 0 ] || curl -fsSL https://raw.githubusercontent.com/zickrian/isle/main/get.sh | bash
echo "Done. Log out and log in to a GNOME session."
