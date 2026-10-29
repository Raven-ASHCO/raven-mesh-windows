# Raven mesh for Windows: Bluetooth nearby over WinRT

Bluetooth nearby lets two laptops exchange [Raven](https://raven-messager.com) messages over
Bluetooth LE when there is no Wi-Fi, cable, hotspot or Internet between them: verified contacts
only, one hop, in radio range. The message is the same end-to-end encrypted object as on any other
way; Bluetooth is only one more carrier. This repository is the Windows part: its honest status,
where the code lives, and how to test it.

## Status: inactive on Windows by design

- **Off in every build.** Bluetooth nearby is held on every operating system by a gate in the code
  (`NEARBY_PRODUCTION_ENABLED = false` in raven-core) until its release record
  (`core/docs/WAIVER_NEARBY_DRAFT.md`, unsigned) is signed after the hardware test rows
  (`core/docs/PHYSICAL_NEARBY_LAPTOPS.md`), which have not been run yet.
- **On Windows it stays inactive even in a lab build.** Raven advertises and connects only from a
  random Bluetooth address, so that nearby devices cannot follow one computer around. Windows does
  not say which address its adverts or its connections go out from, so Raven treats both as the
  PC's fixed public address: **a Windows PC neither advertises nor connects**, and
  `raven nearby status` says nearby is inactive. This changes only if hardware row N7w shows that
  Windows uses a random address.
- **What exists:** a complete WinRT backend in `raven-node` (central and peripheral roles, a GATT
  service per contact, notifications to the one contact only). raven-core CI type-checks it for
  Windows on every push and tests its radio-free part.
- Nothing here is packaged. There is nothing to download.

## Where the code lives

The backend cannot be split out of `raven-node` without breaking its build and tests, so the code
stays in [`raven-core`](https://github.com/Raven-ASHCO/raven-core) (the git submodule at `core/`
here). There is no separate helper program on Windows: raven-node uses WinRT itself.

| What | Where (in `core/`) |
|---|---|
| The WinRT backend: capabilities, state machine, send table (tested on every OS) | `node/crates/raven-node/src/nearby/winrt.rs` |
| Its WinRT calls (`Windows.Devices.Bluetooth`, windows 0.62.2; Windows only) | `node/crates/raven-node/src/nearby/winrt/sys.rs` |
| The radio-independent engine (pair keys, scanning, advertising, the knock, the pipes) | `node/crates/raven-node/src/nearby/` |
| The wire format (RNL1) and its vectors | `protocol/RAVEN_NEARBY_LINK_V1.md`, `shared-vectors/rvn1/nearby/` |
| The user guide | `docs/NEARBY.md` (section 7 is Windows) |

The backend is compiled only with cargo feature `nearby-radio`.

## What Windows needs (once it is active)

- **The user session.** raven-node uses WinRT Bluetooth in your session; the logon task that
  `core/node/scripts/install/windows_service.ps1` registers runs it there. A Windows service is not
  supported for nearby.
- **The peripheral role.** `raven nearby status` says `bluetooth on` when the PC can both scan and
  advertise, or `on, central only` when the adapter (or Windows, for a program that is not a
  packaged app) does not offer the peripheral role. A central-only PC can still reach contacts that
  advertise for it, and both directions then use that link; two central-only PCs can never reach
  each other.
- **Permission.** `not allowed` means Windows refused Bluetooth to raven-node: check the Bluetooth
  and radio entries under Settings > Privacy & security.

## Test

```powershell
git clone --recurse-submodules https://github.com/Raven-ASHCO/raven-mesh-windows.git
cd raven-mesh-windows
pwsh scripts/check.ps1        # on macOS or Linux: scripts/check.sh
```

This runs the backend's tests from `core/node` (Rust via [rustup](https://rustup.rs); raven-core CI
uses 1.98.0, MSVC on Windows). No adapter is used, and the tests use throwaway profiles with
file-backed test stores.

## Lab runs (developers only)

A **debug** build can try the Windows radio anyway with `RAVEN_LAB_NEARBY_ALLOW_PUBLIC_ADDR=1`,
together with the nearby lab switches, on a test profile, never your real one:

```powershell
cd core\node
cargo build --locked -p ash -p raven-node --features raven-node/nearby-radio
$env:RAVEN_LAB_TEST_A = "1"; $env:RAVEN_LAB_NEARBY = "1"; $env:RAVEN_LAB_NEARBY_ALLOW_PUBLIC_ADDR = "1"
$env:RAVEN_DATA_DIR = "$env:USERPROFILE\raven-nearby-test"
```

The PC then reaches a Mac, or a Linux laptop with `Privacy = device`, that advertises for it
(`raven nearby on @<the Windows contact> --for 1h` on that computer). Release builds ignore every
lab switch. While it runs, the PC's fixed Bluetooth address is visible to devices in range.

## Planned

- Hardware rows N3 (Mac to Windows) and N4 (Linux to Windows), and N7w: capture what address
  Windows advertises and connects from. Only if it is random can the Windows radio become active.
- Then the release gate decision (`core/docs/WAIVER_NEARBY_DRAFT.md`).

## License

GNU Affero General Public License v3.0 (`LICENSE`). Security issues: please write to
security@raven-messager.com (`SECURITY.md`), not a public issue.
