#!/bin/sh
# Xcode Cloud runs this after cloning: it installs Flutter and Rust and
# generates the Flutter files the Xcode project needs.
set -e

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
flutter precache --ios
flutter pub get
flutter build ios --release --config-only --build-number="$CI_BUILD_NUMBER"
