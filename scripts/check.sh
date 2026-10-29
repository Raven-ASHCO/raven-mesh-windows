#!/usr/bin/env bash
# The same tests as scripts/check.ps1, for macOS and Linux: the WinRT backend's pure part
# (capabilities, the state machine, the send table) built and tested without Windows.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
NODE="$REPO/core/node"
if [[ ! -f "$NODE/Cargo.toml" ]]; then
  echo "core/ is empty: run 'git submodule update --init' first" >&2
  exit 1
fi
export RAVEN_IDENTITY_BACKEND=locked-file RAVEN_SESSION_BACKEND=locked-file \
  RAVEN_PREKEY_BACKEND=locked-file RAVEN_CHAT_HISTORY_BACKEND=locked-file \
  RAVEN_ALLOW_EPHEMERAL_DATA_DIR=1
cd "$NODE"
cargo test --locked -p raven-node --features nearby-radio --bin raven-node -- nearby::winrt
echo "raven-mesh-windows checks passed"
