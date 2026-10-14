# Embedded local tunnel provenance

AirBeepSwap's `AirBeepTunnel` extension uses adapted code from
[LocalDevVPN](https://github.com/jkcoxson/LocalDevVPN), originally based on
[StosVPN](https://github.com/SideStore/StosVPN), by SideStore Team / Stossy11
and jkcoxson / LocalDevVPN contributors.

Reference revision: `af3fd697803ada4ac2b8d518358f5ab0a534844c`.
Reference file: `TunnelProv/PacketTunnelProvider.swift`.

The fixed local interface and peer routes and IPv4 address-reflection loop
are adapted for AirBeepSwap. Packet validation and tests are added. The full
upstream app, branding and settings UI are not redistributed.

The upstream license is preserved in `LICENSE` and bundled as
`LocalDevVPN-LICENSE.txt` in the containing app. Attribution is also visible
in AirBeepSwap's About screen and main README.
