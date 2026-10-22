#!/usr/bin/env bash
# Bring each formula up to its project's latest GitHub release.
#
# A formula takes part when its url is a release download,
# https://github.com/OWNER/REPO/releases/download/vX.Y.Z/..., and the project
# has a newer release. The new url is the old one with the version swapped;
# sha256 is computed from the downloaded file, so a project needs nothing
# but a release with the same asset name pattern.
#
# Writes one "name version" line per bumped formula to $BUMPED, if set.
# Exits 1 if any formula couldn't be checked or bumped; the others still are.
set -uo pipefail

sha256() {
  if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1
}

status=0
for f in Formula/*.rb; do
  name=$(basename "$f" .rb)
  url=$(sed -n 's|^  url "\(https://github\.com/[^/"]*/[^/"]*/releases/download/[^"]*\)"$|\1|p' "$f" | head -1)
  if [ -z "$url" ]; then
    echo "$name: not a GitHub release download, skipped"
    continue
  fi
  repo=$(echo "$url" | cut -d/ -f4-5)
  tag=$(echo "$url" | cut -d/ -f8)
  if ! latest=$(gh release view -R "$repo" --json tagName --jq .tagName); then
    echo "::error::$name: can't read the latest release of $repo"
    status=1
    continue
  fi
  old=${tag#v}
  new=${latest#v}
  # Only forward: a deleted or re-ordered release never moves a formula back.
  if [ "$old" = "$new" ] || [ "$(printf '%s\n%s\n' "$old" "$new" | sort -V | tail -1)" != "$new" ]; then
    echo "$name: $old is current"
    continue
  fi
  new_url=${url//$old/$new}
  tmp=$(mktemp)
  if ! curl -fsSL "$new_url" -o "$tmp"; then
    echo "::error::$name: $latest has no $new_url"
    rm -f "$tmp"
    status=1
    continue
  fi
  sha=$(sha256 "$tmp")
  rm -f "$tmp"
  awk -v url="$url" -v new_url="$new_url" -v sha="$sha" '
    $0 == "  url \"" url "\"" { print "  url \"" new_url "\""; at_url = 1; next }
    at_url && /^  sha256 "/ { print "  sha256 \"" sha "\""; at_url = 0; next }
    { print }
  ' "$f" > "$f.new" && mv "$f.new" "$f"
  echo "$name: $old -> $new"
  [ -n "${BUMPED:-}" ] && echo "$name $new" >> "$BUMPED"
done
exit $status
