#!/bin/sh
# Bumps the app and CLI versions, commits, tags and pushes a release.
#
#   scripts/release.sh 3.1.0 "Faster scanning on low-end cameras."
#
# Without the notes argument, git opens an editor for them. The notes become
# the tag message, which CI uses as the Linux release notes.
set -e

version=$1
notes=$2

if ! echo "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "usage: scripts/release.sh X.Y.Z [notes]" >&2
  exit 1
fi

cd "$(git rev-parse --show-toplevel)"
tag="v$version"

if [ "$(git branch --show-current)" != main ]; then
  echo "Releases are made from main." >&2
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "Commit or stash your changes first." >&2
  exit 1
fi
git fetch -q origin
if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
  echo "main isn't in sync with origin/main." >&2
  exit 1
fi
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "Tag $tag already exists." >&2
  exit 1
fi

scripts/test.sh

current=$(sed -n 's/^version: *\([^+]*\)+\(.*\)/\1/p' pubspec.yaml)
build=$(sed -n 's/^version: *\([^+]*\)+\(.*\)/\2/p' pubspec.yaml)
newest=$(printf '%s\n%s\n' "$current" "$version" | sort -V | tail -1)
if [ "$version" = "$current" ] || [ "$newest" != "$version" ]; then
  echo "$version isn't newer than the current version $current." >&2
  exit 1
fi

# The build number is Android's versionCode, which must go up every release.
build=$((build + 1))
perl -pi -e "s/^version: .*/version: $version+$build/" pubspec.yaml
perl -pi -e "s/^version = \".*\"/version = \"$version\"/ if 1 .. /^\\[dependencies\\]/" cli/Cargo.toml
(cd cli && cargo update --workspace --offline -q)

git add pubspec.yaml cli/Cargo.toml cli/Cargo.lock
git commit -q -m "Release $tag"
if [ -n "$notes" ]; then
  git tag -a "$tag" -m "$notes"
else
  git tag -a "$tag"
fi

git push -q origin main "$tag"
# Skips the wait for the Codeberg mirror, so release builds start right away.
if git remote get-url github >/dev/null 2>&1; then
  git push -q github main "$tag"
fi

echo "Released $tag (build $build). Publish the GitHub draft once CI is done."
