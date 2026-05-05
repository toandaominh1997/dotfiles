#!/usr/bin/env bash
set -euo pipefail

TMP_HOME="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_HOME"
}
trap cleanup EXIT

export HOME="$TMP_HOME"

cargo run -- --auto --dry-run --verbose

# `--doctor` intentionally exits non-zero when configs/tools are missing,
# which is always the case under a fresh tmp HOME. The smoke test only
# cares that the command runs to completion.
cargo run -- --doctor || true

cargo test --quiet
