# Changelog

All notable changes to **ToneSwap** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## v1.0.0

- Initial ToneSwap release, based on AirBeep 2.4.0 (GPLv3).
- One-switch silence for call-recording disclosure tones (unchanged behavior).
- New: custom tones — pick a local audio file per tone (start/stop independent),
  automatic transcoding to the system format (AAC 44.1 kHz mono `.m4a` /
  PCM s16le 48 kHz mono `.caf`), waveform display, original-vs-replacement
  duration comparison, and in-app preview before applying.
- Backup-first for custom tones, read-back verification after every write,
  one-tap restore of the original tones.
- English + Simplified Chinese UI, legal notice, rewritten About screen.
