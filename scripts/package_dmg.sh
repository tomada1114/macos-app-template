#!/usr/bin/env bash
# Package an .app into a compressed DMG with an /Applications symlink.
# Zero dependencies beyond macOS's built-in hdiutil.
#
#   scripts/package_dmg.sh path/to/MyApp.app [output.dmg]
set -euo pipefail

APP_PATH="${1:?usage: package_dmg.sh path/to/MyApp.app [output.dmg]}"
APP_NAME="$(basename "${APP_PATH}" .app)"
OUTPUT="${2:-${APP_NAME}.dmg}"

[ -d "${APP_PATH}" ] || { echo "error: '${APP_PATH}' is not an app bundle" >&2; exit 1; }

STAGING="$(mktemp -d)"
trap 'rm -rf "${STAGING}"' EXIT

cp -R "${APP_PATH}" "${STAGING}/"
ln -s /Applications "${STAGING}/Applications"

hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGING}" -ov -format UDZO "${OUTPUT}"
echo "Created ${OUTPUT}"
