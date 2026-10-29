# Tests of the Windows nearby radio (the WinRT backend in raven-node), run from the raven-core
# submodule. No Bluetooth adapter is used: the backend's pure part (capabilities, the state
# machine, the send table) is tested on every OS; on Windows the WinRT part is compiled too.
#
#   pwsh scripts/check.ps1
#
# The tests use throwaway profiles with the file-backed test stores, never %USERPROFILE%\.raven.
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$node = Join-Path $repo "core/node"
if (-not (Test-Path (Join-Path $node "Cargo.toml"))) {
    throw "core/ is empty: run 'git submodule update --init' first"
}
$env:RAVEN_IDENTITY_BACKEND = "locked-file"
$env:RAVEN_SESSION_BACKEND = "locked-file"
$env:RAVEN_PREKEY_BACKEND = "locked-file"
$env:RAVEN_CHAT_HISTORY_BACKEND = "locked-file"
$env:RAVEN_ALLOW_EPHEMERAL_DATA_DIR = "1"
Push-Location $node
try {
    cargo test --locked -p raven-node --features nearby-radio --bin raven-node -- nearby::winrt
    if ($LASTEXITCODE -ne 0) { throw "the WinRT backend's tests failed" }
} finally {
    Pop-Location
}
"raven-mesh-windows checks passed"
