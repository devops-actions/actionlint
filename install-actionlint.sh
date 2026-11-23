#!/usr/bin/env bash

# install-actionlint.sh: download the linter release binary (jactionlint) that is pinned in
# settings.json, verify its SHA256 checksum and print the path of the executable.
#
# Reads:  RUNNER_OS, RUNNER_ARCH, RUNNER_TEMP (set by the GitHub Actions runner)
# Writes: the path of the linter executable on stdout, all logging on stderr

set -euo pipefail

log() {
  echo "$*" >&2
}

die() {
  echo "::error::$*" >&2
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
settings="${ACTIONLINT_SETTINGS:-$script_dir/settings.json}"

[[ -f "$settings" ]] || die "Settings file [$settings] not found"
command -v jq >/dev/null 2>&1 || die "jq is required to run this action"
command -v curl >/dev/null 2>&1 || die "curl is required to run this action"

repo=$(jq -r '.actionlintrepo // empty' "$settings")
name=$(jq -r '.actionlintname // empty' "$settings")
version=$(jq -r '.actionlintversiontag // empty' "$settings")

[[ -n "$repo" ]] || die "actionlintrepo is empty in settings.json, cannot continue"
[[ -n "$name" ]] || die "actionlintname is empty in settings.json, cannot continue"
[[ -n "$version" ]] || die "actionlintversiontag is empty in settings.json, cannot continue"

case "${RUNNER_OS:-}" in
  Linux) os="linux"; ext="tar.gz"; exe="$name" ;;
  macOS) os="darwin"; ext="tar.gz"; exe="$name" ;;
  Windows) os="windows"; ext="zip"; exe="$name.exe" ;;
  *) die "Unsupported runner OS [${RUNNER_OS:-}]" ;;
esac

case "${RUNNER_ARCH:-}" in
  X64) arch="amd64" ;;
  ARM64) arch="arm64" ;;
  X86) arch="386" ;;
  ARM) arch="armv6" ;;
  *) die "Unsupported runner architecture [${RUNNER_ARCH:-}]" ;;
esac

platform="${os}_${arch}"
expected=$(jq -r --arg p "$platform" '.checksums[$p] // empty' "$settings")
[[ -n "$expected" ]] || die "No pinned checksum for platform [$platform] in settings.json, this platform is not supported"

asset="${name}_${version}_${platform}.${ext}"
url="https://github.com/${repo}/releases/download/v${version}/${asset}"
installdir="${RUNNER_TEMP:?RUNNER_TEMP is not set}/${name}-${version}-${platform}"
binary="$installdir/$exe"

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  else
    shasum -a 256 "$1" | cut -d ' ' -f 1
  fi
}

rm -rf "$installdir"
mkdir -p "$installdir"

log "Downloading [$repo] version [$version] for [$platform] from [$url]"
curl --fail --silent --show-error --location --retry 3 --output "$installdir/$asset" "$url" \
  || die "Download of [$url] failed"

actual=$(sha256 "$installdir/$asset")
# strip a leading backslash that sha256sum adds on Windows for escaped file names
actual="${actual#\\}"
if [[ "$actual" != "$expected" ]]; then
  rm -f "$installdir/$asset"
  die "Checksum mismatch for [$asset]: expected [$expected] but got [$actual]"
fi
log "Checksum verified [$actual]"

if [[ "$ext" == "zip" ]]; then
  unzip -q -o "$installdir/$asset" "$exe" -d "$installdir" >&2
else
  tar -xzf "$installdir/$asset" -C "$installdir" "$exe"
fi

[[ -f "$binary" ]] || die "Archive [$asset] did not contain [$exe]"
chmod +x "$binary"

echo "$binary"
