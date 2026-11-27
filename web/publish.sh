#!/bin/sh
# Stellt die Handy-Webseite online (Zweig gh-pages): https://pcmanny.github.io/Verlosung/
# Nach Änderungen an Verlosung/index.html einfach erneut ausführen.
set -e
cd "$(dirname "$0")/.."
sh web/build.sh
cd _site
rm -rf .git && git init -q -b gh-pages && git add -A
git -c user.name=PcManny -c user.email="$(git -C .. config user.email)" commit -q -m "Handy-Webseite"
git push -q -f "$(git -C .. remote get-url origin)" gh-pages
rm -rf .git
echo "online: https://pcmanny.github.io/Verlosung/"
