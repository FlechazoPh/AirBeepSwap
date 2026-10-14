# Changelog

All notable changes to **AirBeepSwap** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## v1.1.1

- Add Poner7 maintainer attribution to the main screen, About page, app metadata and project source headers.
- Update English and Chinese READMEs for the Poner7 fork, single-app setup, signing and physical iPhone 18 Pro Max / iOS 27.0.1 install/launch validation.
- Preserve original project credits and third-party licenses.

## v1.1.0

- Embed `AirBeepTunnel.appex` in the same IPA, removing the separate LocalDevVPN installation requirement.
- Connect/disconnect the local tunnel in Airlift Setup, show connection status and reconnect before tone operations when needed.
- Add Network Extension signing entitlements to the main app and extension, with one configurable base bundle identifier.
- Adapt LocalDevVPN / StosVPN packet reflection to a fixed local route; validate IPv4 packets and preserve source attribution/license.
- Add regression checks for TCP/UDP checksums and malformed/unrelated packets, plus archive checks for the embedded extension.
- Physical-device VPN startup and tone operations still require a properly signed app and on-device validation.

## v1.0.2

- Keep iPhone 18 Pro Max / iOS 27.0.1 accepted without a hardware allowlist; add system version boundary checks.
- Rebuild the patched AirliftFFI libraries to include the required read, free and target-host symbols; refresh the checksum manifest after the project rename.
- Show pairing setup on a fresh install, allow reopening setup from the toolbar and recover from cached transient/error states.
- Disable custom tone writes until local setup prerequisites are present.
- Correct duplicate and incorrectly sized app icon entries.
- Explicitly keep audio conversion, FFI logging and symbol lookup off the main actor under Xcode 27's default isolation.
- Add a local unsigned IPA build script and support Rust toolchains outside `~/.cargo`.
- Physical-device pairing and system tone operations on iOS 27.0.1 still require validation.

## v1.0.1

- Rename the project from ToneSwap to AirBeepSwap (app name, bundle ID `eu.flechazo.airbeepswap`, backup directory).

## v1.0.0

- Initial AirBeepSwap release, based on AirBeep 2.4.0 (GPLv3).
- One-switch silence for call-recording disclosure tones (unchanged behavior).
- New: custom tones — pick a local audio file per tone (start/stop independent),
  automatic transcoding to the system format (AAC 44.1 kHz mono `.m4a` /
  PCM s16le 48 kHz mono `.caf`), waveform display, original-vs-replacement
  duration comparison, and in-app preview before applying.
- Backup-first for custom tones, read-back verification after every write,
  one-tap restore of the original tones.
- English + Simplified Chinese UI, legal notice, rewritten About screen.
