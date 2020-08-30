#!/bin/bash

# exit when any command fails
set -e

readonly app_name="MintAmazonTagger"
readonly bundle_ident="com.jeffprouty.mintamazontagger"
readonly app_identity="Developer ID Application: Jeff Prouty (NRC455QXS5)"
readonly email="jeff.prouty@gmail.com"

readonly app_dir="dist/MintAmazonTagger.app"
readonly dmg_path="dist/${app_name}.dmg"
readonly entitlements="release/entitlements.plist"
readonly icon_icns="build/Icon.icns"

cd "$(dirname "$0")/.."

echo "Clean everything"
python3 setup.py clean

echo "Setup the release venv"
python3 -m venv release_venv
source release_venv/bin/activate
pip install --upgrade pip
pip install --upgrade -r requirements/base.txt

mkdir build

# Create an icns file
iconutil -c icns icons/mac.iconset --output="${icon_icns}"

pyinstaller \
  --name="${app_name}" \
  --windowed \
  --icon="${icon_icns}" \
  --osx-bundle-identifier="${bundle_ident}" \
  mintamazontagger/main.py

deactivate
rm -rf release_venv

echo "Signing the app"
codesign --verify --verbose --force --deep --sign \
  "${app_identity}" \
  --entitlements "${entitlements}" \
  --options=runtime \
  "${app_dir}"

echo "Creating installer/disk image"
readonly temp_dmg="dist/${app_name}.temp.dmg"
hdiutil create \
  -srcfolder "${app_dir}" \
  -volname "${app_name}" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" \
  -format UDRW \
  "${temp_dmg}"

readonly mount_path="/Volumes/${app_name}"
dev_name=$(hdiutil info | egrep --color=never '^/dev/' | sed 1q | awk '{print $1}')
test -d "${mount_path}" && hdiutil detach "${dev_name}"

# Mount the image as RW.
dev_name=$(hdiutil attach -readwrite -noverify -noautoopen "${temp_dmg}" | egrep --color=never '^/dev/' | sed 1q | awk '{print $1}')
# Link in the apps dir
ln -s /Applications "$mount_path/Applications"
# Copy the icon, for fun.
cp "${icon_icns}" "$mount_path/.VolumeIcon.icns"
SetFile -c icnC "$mount_path/.VolumeIcon.icns"

# Run the thing
"/usr/bin/osascript" "release/dmg.applescript" "${app_name}" || true
sleep 2

chmod -Rf go-w "${mount_path}" &> /dev/null || true

bless --folder "${mount_path}" --openfolder "${mount_path}"

# tell the volume that it has a special file attribute for the icons.
SetFile -a C "${mount_path}"

hdiutil detach "${dev_name}"
hdiutil convert "${temp_dmg}" \
  -format "UDZO" \
  -imagekey zlib-level=9 \
  -o "${dmg_path}"
rm -f "${temp_dmg}"

echo "Signing dmg"
codesign --verify --verbose --force --deep --sign \
  "${app_identity}" \
  --entitlements "${entitlements}" \
  --options=runtime \
  "${dmg_path}"

echo "Creating an Apple notary request"
xcrun altool --notarize-app \
    --primary-bundle-id "${bundle_ident}" \
    --username "${email}" \
    --password "@keychain:AC_PASSWORD" \
    --file "${dmg_path}"

echo "Check notary status later via: "
echo "xcrun altool --notarization-history 0 -u \"${email}\" -p \"@keychain:AC_PASSWORD\""
echo "  AND"
echo "xcrun altool --notarization-info <REQUEST_ID> -u \"${email}\""
echo
echo "Once successful, staple and you're done!:"
echo "xcrun stapler staple \"${dmg_path}\"
