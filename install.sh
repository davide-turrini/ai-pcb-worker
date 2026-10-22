#!/bin/sh
# Installs pcbmate-worker on macOS or Linux:
#   curl -fsSL https://raw.githubusercontent.com/pcbmate/worker-cli/main/install.sh | sh
# The latest version is in latest.json; the executable comes from its release, checked against the
# release's SHA256SUMS, and goes to ~/.pcbmate-worker/bin. Then `setup` downloads the tools.
set -eu

# All in a function called on the last line: a download cut halfway runs nothing.
main() {
  REPO=https://github.com/pcbmate/worker-cli
  RAW=https://raw.githubusercontent.com/pcbmate/worker-cli/main
  HOME_DIR=${PCBMATE_WORKER_HOME:-$HOME/.pcbmate-worker}

  case "$(uname -s)" in
    Darwin) os=darwin ;;
    Linux) os=linux ;;
    *) echo "pcbmate-worker: this script is for macOS and Linux (Windows: install.ps1)" >&2; exit 1 ;;
  esac
  case "$(uname -m)" in
    arm64 | aarch64) arch=arm64 ;;
    x86_64 | amd64) arch=x64 ;;
    *) echo "pcbmate-worker: no build for $(uname -m)" >&2; exit 1 ;;
  esac

  version=$(curl -fsSL "$RAW/latest.json" | sed -n 's/.*"version" *: *"\([0-9][0-9.]*\)".*/\1/p')
  [ -n "$version" ] || { echo "pcbmate-worker: cannot read the latest version" >&2; exit 1; }
  name="pcbmate-worker-$version-$os-$arch"
  echo "Installing pcbmate-worker $version for $os-$arch"

  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  curl -fL --progress-bar -o "$tmp/$name" "$REPO/releases/download/worker-$version/$name"
  curl -fsSL -o "$tmp/SHA256SUMS" "$REPO/releases/download/worker-$version/SHA256SUMS"
  expected=$(awk -v n="$name" '$2 == n { print $1 }' "$tmp/SHA256SUMS")
  if command -v shasum >/dev/null 2>&1; then
    actual=$(shasum -a 256 "$tmp/$name" | awk '{ print $1 }')
  else
    actual=$(sha256sum "$tmp/$name" | awk '{ print $1 }')
  fi
  if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
    echo "pcbmate-worker: the download does not match its checksum" >&2
    exit 1
  fi

  mkdir -p "$HOME_DIR/bin"
  chmod 755 "$tmp/$name"
  mv "$tmp/$name" "$HOME_DIR/bin/pcbmate-worker"
  exe="$HOME_DIR/bin/pcbmate-worker"
  "$exe" setup

  # A short name when ~/.local/bin is on the PATH (most Linux systems).
  case ":$PATH:" in
    *":$HOME/.local/bin:"*)
      mkdir -p "$HOME/.local/bin"
      ln -sf "$exe" "$HOME/.local/bin/pcbmate-worker"
      exe=pcbmate-worker
      ;;
  esac
  echo
  echo "Done. Connect this computer with a token from pcbmate's Workers page:"
  echo "  $exe login <token> --api <https://your-pcbmate>"
  echo "  $exe run"
}

main "$@"
