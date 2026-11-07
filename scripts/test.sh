#!/bin/sh
# Runs every test suite. Used by CI and scripts/release.sh.
set -e

cd "$(git rev-parse --show-toplevel)"

flutter test
(cd packages/blastqr_crypto/rust && cargo build --release --locked)
(cd packages/blastqr_crypto && flutter test)
(cd packages/blastqr_envelope && cargo test)
(cd cli && cargo test --locked)
