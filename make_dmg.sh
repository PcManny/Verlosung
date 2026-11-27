#!/bin/bash
# Erzeugt ein hübsches DMG: App links, Programme-Ordner rechts, Pfeil dazwischen.
# Aufruf: make_dmg.sh <App.app> <Ausgabe.dmg> <Hintergrund.png> [weitere Dateien …]
# Unterschreibt und beglaubigt das DMG, wenn Developer ID + Notar-Profil vorhanden sind.
set -euo pipefail
APP="$1"; OUT="$2"; BG="$3"; shift 3
NAME=$(basename "$APP" .app)
PROFILE="${NOTARY_PROFILE:-MacCleaner-Notar}"
WORK=$(mktemp -d); STAGE="$WORK/$NAME"
mkdir -p "$STAGE/.background"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Programme"
cp "$BG" "$STAGE/.background/bg.png"
BG2="${BG%.png}@2x.png"; [ -f "$BG2" ] && cp "$BG2" "$STAGE/.background/bg@2x.png"
for f in "$@"; do cp "$f" "$STAGE/"; done
rm -f "$OUT"
hdiutil create -quiet -srcfolder "$STAGE" -volname "$NAME" -fs HFS+ -format UDRW -ov "$WORK/rw.dmg"
DEV=$(hdiutil attach -readwrite -noverify -noautoopen "$WORK/rw.dmg" | awk '/Apple_HFS/ {print $1}')
VOL="/Volumes/$NAME"
# Fensterlayout per Finder (klappt nur, wenn Terminal/Claude den Finder steuern darf – sonst schlichtes Fenster)
EXTRA=""; X=120
for f in "$@"; do EXTRA="$EXTRA
      set position of item \"$(basename "$f")\" of container window to {$X, 330}"; X=$((X+170)); done
osascript <<OSA || echo "Hinweis: Fensterlayout nicht gesetzt (Finder-Steuerung nicht erlaubt)."
tell application "Finder"
  tell disk "$NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 840, 548}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to 96
    set text size of opts to 13
    set background picture of opts to file ".background:bg.png"
    set position of item "$NAME.app" of container window to {170, 175}
    set position of item "Programme" of container window to {470, 175}$EXTRA
    close
    open
    update without registering applications
    delay 1
    close
  end tell
end tell
OSA
sync; sleep 1
hdiutil detach -quiet "$DEV" || hdiutil detach -force -quiet "$DEV"
hdiutil convert -quiet "$WORK/rw.dmg" -format UDZO -imagekey zlib-level=9 -o "$OUT"
rm -rf "$WORK"
ID=$(security find-identity -v -p codesigning | awk '/Developer ID Application/ {print $2; exit}')
if [[ -n "$ID" ]]; then
  codesign --force --timestamp --sign "$ID" "$OUT"
  if xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
    echo "DMG wird bei Apple beglaubigt …"
    xcrun notarytool submit "$OUT" --keychain-profile "$PROFILE" --wait | tee "$OUT.notar.log"
    grep -q "status: Accepted" "$OUT.notar.log" || { echo "DMG-Beglaubigung fehlgeschlagen"; exit 1; }
    rm -f "$OUT.notar.log"
    xcrun stapler staple "$OUT"
  fi
fi
echo "DMG fertig: $OUT"
