#!/bin/sh
# Xcode Cloud runs this after cloning: it installs Flutter and Rust and
# generates the Flutter files the Xcode project needs. The macOS workflow
# runs it too, through macos/ci_scripts/ci_post_clone.sh.
set -e

case "$CI_PRODUCT_PLATFORM" in
  macOS) platform=macos ;;
  *) platform=ios ;;
esac

# Keep in sync with .github/workflows/release.yml.
FLUTTER_VERSION=3.47.8

git clone --depth 1 --branch "$FLUTTER_VERSION" \
  https://github.com/flutter/flutter.git "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

# Installs to ~/.cargo/bin, which the Runner build phase adds to PATH for the
# Rust build hooks.
curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain none --profile minimal

cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter --disable-analytics
flutter precache --$platform
flutter pub get
flutter build $platform --release --config-only --build-number="$CI_BUILD_NUMBER"
