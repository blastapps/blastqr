#!/bin/sh
# Runs every test suite. Used by CI and scripts/release.sh.
set -e

cd "$(git rev-parse --show-toplevel)"

python3 fonts/DNFBitBit/build_subset.py --check
flutter test
(cd packages/blastqr_crypto/rust && cargo build --release --locked)
(cd packages/blastqr_crypto && flutter test)
(cd packages/blastqr_video && flutter test)
(cd packages/blastqr_envelope && cargo test)
(cd cli && cargo test --locked)
