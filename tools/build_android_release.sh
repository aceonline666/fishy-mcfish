#!/usr/bin/env bash
# Build the signed Play Store bundle (build/fishy-mcfish.aab). It only builds: uploading to
# Play Console is done by hand.
#
# The upload keystore and its password live in 1Password (personal account, vault "Gaming",
# item "Fishy McFish Key"). The item is read with one op call (one authorization prompt); the
# keystore comes from its base64 field and is written to a temp folder deleted on exit.
#
# Usage: tools/build_android_release.sh [--bump]
#   --bump   raise version/code in the "Android Play Store" preset by one before exporting
#            (Play rejects an upload whose version code was already used)
#
# Overrides: GODOT (path to the Godot exe), OP_ACCOUNT, OP_VAULT, OP_ITEM, ANDROID_HOME, JAVA_HOME.
set -euo pipefail

cd "$(dirname "$0")/.."

GODOT="${GODOT:-C:/Program Files/Godot/Godot_v4.7.2-stable_win64.exe}"
PRESET="Android Play Store"
OUT="build/fishy-mcfish.aab"
OP_ACCOUNT="${OP_ACCOUNT:-my.1password.eu}"
OP_VAULT="${OP_VAULT:-Gaming}"
OP_ITEM="${OP_ITEM:-Fishy McFish Key}"
export ANDROID_HOME="${ANDROID_HOME:-C:/Program Files/Android/Sdk}"
export JAVA_HOME="${JAVA_HOME:-C:/Program Files/Microsoft/jdk-17.0.20.101-hotspot}"

die() { echo "error: $*" >&2; exit 1; }

# 1Password CLI: on PATH, or where winget puts it
OP="$(command -v op || true)"
[ -n "$OP" ] || OP="$(ls "$LOCALAPPDATA"/Microsoft/WinGet/Packages/AgileBits.1Password.CLI_*/op.exe 2>/dev/null | head -n1 || true)"
[ -n "$OP" ] || die "1Password CLI (op) not found; install it with: winget install AgileBits.1Password.CLI"
[ -f "$GODOT" ] || die "Godot not found at $GODOT (set GODOT=...)"
[ -d "$ANDROID_HOME/platforms/android-35" ] || die "Android SDK platform 35 missing in $ANDROID_HOME"

if [ "${1:-}" = "--bump" ]; then
    # The preset's second block ([preset.1.options]) is the Play Store one
    code="$(awk '/^\[preset\.1\.options\]/{f=1} f&&/^version\/code=/{sub(/.*=/,"");print;exit}' export_presets.cfg | tr -d '\r')"
    [ -n "$code" ] || die "could not find version/code in preset.1"
    sed -i "/^\[preset\.1\.options\]/,\$ s/^version\/code=.*/version\/code=$((code + 1))/" export_presets.cfg
    echo "version/code: $code -> $((code + 1))"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK:?}"' EXIT
KEYSTORE="$WORK/release.keystore"

echo "Reading the upload key from 1Password..."
ITEM_JSON="$("$OP" --account "$OP_ACCOUNT" item get "$OP_ITEM" --vault "$OP_VAULT" --format json)"     || die "could not read the 1Password item (is 1Password unlocked?)"
field() { python -c 'import sys,json; f={x.get("label"):x.get("value","") for x in json.load(sys.stdin)["fields"]}; sys.stdout.write(f.get(sys.argv[1],""))' "$1" <<<"$ITEM_JSON"; }
field keystore_b64 | base64 -d > "$KEYSTORE"
[ -s "$KEYSTORE" ] || die "item has no keystore_b64 field"
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(field password)"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$(cygpath -m "$KEYSTORE")"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$(field "Key alias")"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:=fishy}"
ITEM_JSON=""

rm -f "$OUT"
echo "Exporting \"$PRESET\"..."
"$GODOT" --headless --path . --export-release "$PRESET" 2>&1 | grep -viE "pass:|password" | tail -n "${LOG_LINES:-8}" || true

[ -s "$OUT" ] || die "export produced no $OUT"
verify="$("$JAVA_HOME/bin/jarsigner.exe" -verify "$OUT" 2>&1 || true)"
grep -q "jar verified" <<<"$verify" || die "$OUT is not validly signed"
unzip -p "$OUT" base/manifest/AndroidManifest.xml | grep -aq "com.aceonline666.fishymcfish" || die "unexpected package name in $OUT"

code="$(awk '/^\[preset\.1\.options\]/{f=1} f&&/^version\/code=/{sub(/.*=/,"");print;exit}' export_presets.cfg | tr -d '\r')"
name="$(awk '/^\[preset\.1\.options\]/{f=1} f&&/^version\/name=/{sub(/.*=/,"");print;exit}' export_presets.cfg | tr -d '\r')"
echo
echo "Signed bundle ready: $OUT ($(du -h "$OUT" | cut -f1)), version code $code, name $name"
echo "Not uploaded. To release: Play Console > Release > Testing > Internal testing > Create new release."
