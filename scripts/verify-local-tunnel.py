#!/usr/bin/env python3
# AirBeepSwap — maintained by Poner7.
# https://github.com/poner7/AirBeepSwap
"""Validate the embedded extension before packaging an unsigned IPA."""
import pathlib
import plistlib
import sys

root = pathlib.Path(__file__).resolve().parents[1]
for path in [root / 'airbeepswap/AirBeepSwap.entitlements', root / 'AirBeepTunnel/AirBeepTunnel.entitlements']:
    with path.open('rb') as file:
        entitlements = plistlib.load(file)
    assert 'packet-tunnel-provider' in entitlements['com.apple.developer.networking.networkextension'], path

app = pathlib.Path(sys.argv[1])
extension = app / 'PlugIns/AirBeepTunnel.appex'
with (app / 'Info.plist').open('rb') as file:
    main_info = plistlib.load(file)
with (extension / 'Info.plist').open('rb') as file:
    extension_info = plistlib.load(file)
assert extension_info['CFBundleIdentifier'].startswith(main_info['CFBundleIdentifier'] + '.')
for key in ['CFBundleShortVersionString', 'CFBundleVersion']:
    assert main_info[key] == extension_info[key], f'{key} mismatch'
assert extension_info['NSExtension']['NSExtensionPointIdentifier'] == 'com.apple.networkextension.packet-tunnel'
assert extension_info['NSExtension']['NSExtensionPrincipalClass'].endswith('.PacketTunnelProvider')
assert (extension / extension_info['CFBundleExecutable']).is_file()
assert (app / 'LocalDevVPN-LICENSE.txt').is_file()
assert 'localdevvpn' not in main_info.get('LSApplicationQueriesSchemes', [])
print('Embedded local tunnel, bundle IDs, versions, entitlements sources and attribution verified')
print('Unsigned package: signing profiles and VPN startup still require physical-device validation')
