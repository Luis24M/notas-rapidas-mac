#!/bin/sh
# Compila la app y la instala en /Applications, reiniciándola si estaba abierta.
set -eu
cd "$(dirname "$0")/.."

# Las Command Line Tools no incluyen las macros de SwiftUI: hace falta el toolchain de Xcode.
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build -c release

app=/Applications/NotasRapidas.app
pkill -x NotasRapidas || true
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp .build/release/NotasRapidas "$app/Contents/MacOS/"
cp Info.plist "$app/Contents/"
cp Resources/AppIcon.icns "$app/Contents/Resources/"
codesign --force --sign - "$app"
open "$app"
