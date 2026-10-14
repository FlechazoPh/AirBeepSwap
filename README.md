# AirBeepSwap

> 🌍 **Languages:** [English](./README.md) | [简体中文](./README_zh-CN.md)

**Maintained and adapted by [Poner7](https://github.com/poner7).** This fork is hosted at [poner7/AirBeepSwap](https://github.com/poner7/AirBeepSwap) and is based on [FlechazoPh/AirBeepSwap](https://github.com/FlechazoPh/AirBeepSwap). Original author credits and licenses are preserved.

AirBeepSwap is an iOS tool for customizing the call-recording disclosure tones — the sounds iOS plays when call recording starts and stops. Silence them with one switch, or replace each tone with your own audio file: pick a file, see its waveform and duration, preview it, and apply it. Original tones are backed up before the first change and can be restored with one tap.

## Features

- **One app to install**: the local tunnel is embedded in AirBeepSwap, with in-app connect/disconnect controls.
- Poner7 attribution in the main screen, About page and source files.
- One switch silences both disclosure tones (equal-length silence, like AirBeep).
- **Custom tones**: pick any local audio file (MP3, M4A, WAV, CAF, AIFF…) per tone — start and stop are independent.
- Automatic transcoding to the exact system format (AAC 44.1 kHz mono `.m4a` for the start tone, PCM s16le 48 kHz mono `.caf` for the stop tone), so iOS plays the replacement natively.
- Waveform display, original-vs-replacement duration comparison, and in-app preview before applying.
- First change automatically backs up the original tone files — backups are kept and never overwritten.
- Every write is verified by reading the file back from the device.
- One-tap restore of the original tones.
- English and Simplified Chinese UI.

## How it works

AirBeepSwap accesses the system tone files through the same AirTraffic sandbox escape as [AirBeep](https://github.com/LinkPass888/AirBeep):

- `/var/mobile/Library/CallServices/Greetings/default/StartDisclosureWithTone.m4a`
- `/var/mobile/Library/CallServices/Greetings/default/StopDisclosure.caf`

The app pairs with the iPhone itself (posing as a Mac pairing host over Bonjour/RPPairing). Its embedded `AirBeepTunnel` Network Extension supplies a local loopback route, and the Airlift core accesses the device services through that route. Only AirBeepSwap needs to be installed. Backups live in the app's Documents directory under `AirBeepSwapBackups`.

## Requirements

- A physical iPhone or iPad running **iOS/iPadOS 26.0 – 27.2 B2** for the default IPA (the source version check also allows 18–25, but the current build target is 26.0).
- A paid Apple Developer account and signing profiles permitting Network Extension for both the app and its embedded extension.
- Pair with the app, then connect its built-in tunnel and approve the iOS VPN configuration prompt. A separate LocalDevVPN installation is no longer required.
- Local builds need Xcode 27 or newer.
- The provided GitHub Actions workflow builds an unsigned IPA in the cloud.

### iPhone 18 Pro Max / iOS 27.0.1

iOS 27.0.1 is accepted by the system version check; there is no iPhone model allowlist. Version 1.0.2 fixes the missing Airlift file-access symbols and shows pairing setup on a fresh install. Version 1.1.0 adds the embedded local tunnel. The shipping target remains iOS 26.0, so iOS 27.0.1 meets the installation requirement.

On October 14, 2026, the app and embedded extension were signed with the required Network Extension permissions, installed and launched on a physical iPhone 18 Pro Max running iOS 27.0.1. System version checks, packet reflection tests, archive validation and simulator launch also passed. Actual pairing, tunnel connectivity and system tone read/write operations still require device validation.

> AirBeepSwap relies on non-public system behavior; compatibility may change between iOS versions.

## Setup

1. Install the app and open it.
2. Complete pairing in **Airlift Setup**: start pairing and approve the PIN in Settings › Privacy & Security › Developer Mode.
3. Return to the app, tap **Connect tunnel**, approve the iOS VPN configuration prompt, then tap **Check and enter**.
4. Use the silence switch, or pick custom audio per tone and tap **Replace with this audio**. After the operation finishes, you can disconnect the tunnel from Airlift Setup.

## Build

Open `airbeepswap.xcodeproj`, select the `airbeepswap` scheme, configure signing for both `airbeepswap` and `AirBeepTunnel`, and build to a physical device.

For an unsigned IPA, run the `Release unsigned IPA` workflow in GitHub Actions. The artifact is named `airbeepswap-v<version>-unsigned.ipa`.

To build locally without a signing team, run `bash scripts/build-unsigned-ipa.sh`. It checks the system version boundaries and Airlift integration, then writes the IPA to `build/unsigned/`. Sign the IPA with your own certificate before installing it. If rebuilding the native core, install Rust and run `bash scripts/build-airlift-xcframework.sh` first.

### Signing the single-app build

1. Use your paid developer team for **both** targets.
2. Set the project's `AIRBEEP_BUNDLE_IDENTIFIER` build setting to your own unique app ID, for example `com.yourname.airbeep`. The extension ID is derived as `com.yourname.airbeep.tunnel`.
3. Enable **Network Extensions / Packet Tunnel** for both App IDs and **Personal VPN** for the main app. Regenerate the matching provisioning profiles, or let Xcode's automatic signing manage them.
4. Preserve the embedded `PlugIns/AirBeepTunnel.appex` when signing an IPA; sign the extension and the containing app with their corresponding profiles under the same team. A signer that removes extensions or strips these entitlements will disable the tunnel.

Unsigned archives and simulator launches cannot confirm VPN authorization or device-service connectivity. Validate connection, tone backup/replacement and restore on the physical iPhone after signing.

## Legal notice

Removing or replacing the disclosure tone means the other party is no longer told the call is being recorded. Many jurisdictions require informing all parties before recording a call. Use this app only on your own device and only where the law allows. You are solely responsible for complying with applicable laws.

## Credits

- [Poner7](https://github.com/poner7) — this fork's maintainer; iPhone 18 Pro Max / iOS 27.0.1 adaptation, embedded local tunnel integration and build fixes.
- [AirBeepSwap](https://github.com/FlechazoPh/AirBeepSwap) (FlechazoPh) — the original custom-tone app this fork is based on.
- [AirBeep](https://github.com/LinkPass888/AirBeep) (LinkPass888, GPLv3) — the iOS app this project is based on.
- [airlift](https://github.com/0xjohnnydev/airlift) (0xjohnnydev, MIT) — AirTraffic sandbox escape research.
- [AirliftSilence](https://github.com/YiHoooong/AirliftSilence) (MIT) — silent assets and replace protocol.
- [AirCard](https://github.com/mak5er/AirCard-iOS) — the Rust Airlift core.
- [placard](https://github.com/frs0n/placard) (frs0n) — iOS container access research.
- [LocalDevVPN](https://github.com/jkcoxson/LocalDevVPN) / [StosVPN](https://github.com/SideStore/StosVPN) (SideStore Team / Stossy11 and jkcoxson / contributors) — the embedded tunnel uses adapted packet-loop code. See [provenance and license](Vendor/LocalTunnel/README.md); the original license is also bundled in the app.

## License

AirBeepSwap is released under the [GNU General Public License v3.0](LICENSE), following the license of the AirBeep codebase it derives from.
