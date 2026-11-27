#!/bin/sh
# Baut die Handy-Webseite (GitHub Pages) nach _site/. Online stellen: web/publish.sh
# Google-Schriften werden weggelassen: so geht beim Öffnen nichts an Google (Datenschutz).
set -e
cd "$(dirname "$0")/.."
rm -rf _site && mkdir _site
grep -v 'fonts.googleapis.com\|fonts.gstatic.com' Verlosung/index.html > _site/index.html
cp web/manifest.webmanifest web/sw.js web/icon-*.png _site/
touch _site/.nojekyll
echo "fertig: _site/"
