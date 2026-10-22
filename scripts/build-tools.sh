#!/usr/bin/env bash
# Builds the tools archive of ai-pcb-worker for one system:
#   scripts/build-tools.sh <darwin-arm64|darwin-x64|linux-x64|linux-arm64|win32-x64> <release>
# → dist/ai-pcb-tools-<release>-<system>.tar.gz with jre/ (Temurin 25 reduced with jlink),
#   freerouting.jar (2.4.1, checked) and ngspice/ (44.2: built from source, official binaries on Windows).
set -euo pipefail
SYSTEM="$1"
RELEASE="$2"
FREEROUTING_SHA256=251101c3eeac22d7e7dfcf6796603279e5d1000283eb82d8f093780f7afc6aa9
NGSPICE=44.2
# From jdeps on the unpacked Freerouting jar (its nested module descriptors confuse jdeps on the jar).
MODULES=java.base,java.compiler,java.desktop,java.instrument,java.naming,java.net.http,java.rmi,java.scripting,java.security.jgss,java.sql,jdk.attach,jdk.jdi,jdk.management,jdk.unsupported,jdk.crypto.ec

ROOT="$(pwd)"
WORK="$ROOT/work/$SYSTEM"
OUT="$WORK/tools"
rm -rf "$WORK" && mkdir -p "$OUT" "$ROOT/dist"
cd "$WORK"
step() { printf '\n== %s\n' "$1"; }
# shasum where it exists (macOS, some Linux), sha256sum otherwise (Windows Git Bash).
sha256check() { if command -v shasum > /dev/null; then shasum -a 256 -c; else sha256sum -c; fi; }

case "$SYSTEM" in
  darwin-arm64) OS=mac; ARCH=aarch64 ;;
  darwin-x64) OS=mac; ARCH=x64 ;;
  linux-x64) OS=linux; ARCH=x64 ;;
  linux-arm64) OS=linux; ARCH=aarch64 ;;
  win32-x64) OS=windows; ARCH=x64 ;;
  *) echo "unknown system $SYSTEM" >&2; exit 2 ;;
esac

step "Temurin 25 JDK for $OS $ARCH, reduced with jlink"
if [ "$OS" = windows ]; then
  curl -fsSL -o jdk.zip "https://api.adoptium.net/v3/binary/latest/25/ga/windows/x64/jdk/hotspot/normal/eclipse"
  mkdir jdk && unzip -q jdk.zip -d jdk && JDK="$(ls -d jdk/*/)"
  JLINK="$JDK/bin/jlink.exe"; JAVA="$OUT/jre/bin/java.exe"
else
  curl -fsSL -o jdk.tar.gz "https://api.adoptium.net/v3/binary/latest/25/ga/$OS/$ARCH/jdk/hotspot/normal/eclipse"
  mkdir jdk && tar -xzf jdk.tar.gz -C jdk --strip-components=1
  JDK=jdk; [ "$OS" = mac ] && JDK=jdk/Contents/Home
  JLINK="$JDK/bin/jlink"; JAVA="$OUT/jre/bin/java"
fi
"$JLINK" --add-modules "$MODULES" --strip-debug --no-man-pages --no-header-files --compress=zip-9 --output "$OUT/jre"

step "Freerouting 2.4.1"
curl -fsSL -o "$OUT/freerouting.jar" https://github.com/freerouting/freerouting/releases/download/v2.4.1/freerouting-2.4.1.jar
echo "$FREEROUTING_SHA256  $OUT/freerouting.jar" | sha256check

step "ngspice $NGSPICE"
mkdir -p "$OUT/ngspice/bin"
if [ "$OS" = windows ]; then
  # The official Windows build; the console program is the one for batch runs.
  curl -fsSL -o ngspice.7z "https://downloads.sourceforge.net/project/ngspice/ng-spice-rework/old-releases/$NGSPICE/ngspice-${NGSPICE}_64.7z"
  7z x -y -ongspice-win ngspice.7z > /dev/null
  cp ngspice-win/Spice64/bin/ngspice_con.exe "$OUT/ngspice/bin/ngspice.exe"
  cp ngspice-win/Spice64/bin/*.dll "$OUT/ngspice/bin/" 2>/dev/null || true
else
  curl -fsSL -o ngspice.tar.gz "https://downloads.sourceforge.net/project/ngspice/ng-spice-rework/old-releases/$NGSPICE/ngspice-$NGSPICE.tar.gz"
  mkdir ngspice-src && tar -xzf ngspice.tar.gz -C ngspice-src --strip-components=1
  EXTRA_LD=""; [ "$OS" = linux ] && EXTRA_LD="-static-libstdc++ -static-libgcc"
  ( cd ngspice-src && CXXFLAGS="-O2 -Wno-invalid-specialization" LDFLAGS="$EXTRA_LD" ./configure --prefix="$OUT/ngspice" --without-x --with-readline=no --disable-openmp --disable-debug --enable-cider=no > ../configure.log 2>&1 \
      || { tail -40 ../configure.log; exit 1; } )
  ( cd ngspice-src && make -j4 > ../make.log 2>&1 || { tail -40 ../make.log; exit 1; } )
  ( cd ngspice-src && make install > ../install.log 2>&1 )
  rm -rf "$OUT/ngspice/share/man" "$OUT/ngspice/include"
fi

step "Checks"
"$JAVA" -version 2>&1 | head -1
"$OUT/ngspice/bin/ngspice$([ "$OS" = windows ] && echo .exe)" -v 2>&1 | head -2 || true
du -sh "$OUT"/* | sed 's/^/  /'

step "Archive"
ARCHIVE="ai-pcb-tools-$RELEASE-$SYSTEM.tar.gz"
tar -czf "$ROOT/dist/$ARCHIVE" -C "$OUT" .
ls -la "$ROOT/dist/$ARCHIVE"
