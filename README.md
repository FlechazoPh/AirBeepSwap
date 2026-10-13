# ToneSwap

> 🌍 **Languages:** [English](./README.md) | [简体中文](./README_zh-CN.md)

ToneSwap is an iOS tool for customizing the call-recording disclosure tones — the sounds iOS plays when call recording starts and stops. Silence them with one switch, or replace each tone with your own audio file: pick a file, see its waveform and duration, preview it, and apply it. Original tones are backed up before the first change and can be restored with one tap.

## Features

- One switch silences both disclosure tones (equal-length silence, like AirBeep).
- **Custom tones**: pick any local audio file (MP3, M4A, WAV, CAF, AIFF…) per tone — start and stop are independent.
- Automatic transcoding to the exact system format (AAC 44.1 kHz mono `.m4a` for the start tone, PCM s16le 48 kHz mono `.caf` for the stop tone), so iOS plays the replacement natively.
- Waveform display, original-vs-replacement duration comparison, and in-app preview before applying.
- First change automatically backs up the original tone files — backups are kept and never overwritten.
- Every write is verified by reading the file back from the device.
- One-tap restore of the original tones.
- English and Simplified Chinese UI.

## How it works

ToneSwap accesses the system tone files through the same AirTraffic sandbox escape as [AirBeep](https://github.com/LinkPass888/AirBeep):

- `/var/mobile/Library/CallServices/Greetings/default/StartDisclosureWithTone.m4a`
- `/var/mobile/Library/CallServices/Greetings/default/StopDisclosure.caf`

The app pairs with the iPhone itself (posing as a Mac pairing host over Bonjour/RPPairing), opens a tunnel to the device's lockdown services, and performs the file operations through the Airlift core. Backups live in the app's Documents directory under `ToneSwapBackups`.

## Requirements

- A physical iPhone or iPad running **iOS/iPadOS 18.0 – 27.2 B2**.
- The iPhone must be paired with the app and connected via LocalDevVPN (in-app setup walks you through it).
- Local builds need Xcode 27 or newer.
- The provided GitHub Actions workflow builds an unsigned IPA in the cloud.

> ToneSwap relies on non-public system behavior; compatibility may change between iOS versions.

## Setup

1. Install the app and open it.
2. Complete **Airlift Setup** in the app: start pairing, approve the PIN in Settings › Privacy & Security › Developer Mode, then connect LocalDevVPN.
3. Use the silence switch, or pick custom audio per tone and tap **Replace with this audio**.

## Build

Open `toneswap.xcodeproj`, select the `toneswap` target, set your signing team, and build to a physical device.

For an unsigned IPA, run the `Release unsigned IPA` workflow in GitHub Actions. The artifact is named `toneswap-v<version>-unsigned.ipa`.

## Legal notice

Removing or replacing the disclosure tone means the other party is no longer told the call is being recorded. Many jurisdictions require informing all parties before recording a call. Use this app only on your own device and only where the law allows. You are solely responsible for complying with applicable laws.

## Credits

- [AirBeep](https://github.com/LinkPass888/AirBeep) (LinkPass888, GPLv3) — the iOS app this project is based on.
- [airlift](https://github.com/0xjohnnydev/airlift) (0xjohnnydev, MIT) — AirTraffic sandbox escape research.
- [AirliftSilence](https://github.com/YiHoooong/AirliftSilence) (MIT) — silent assets and replace protocol.
- [AirCard](https://github.com/mak5er/AirCard-iOS) — the Rust Airlift core.
- [placard](https://github.com/frs0n/placard) (frs0n) — iOS container access research.

## License

ToneSwap is released under the [GNU General Public License v3.0](LICENSE), following the license of the AirBeep codebase it derives from.
