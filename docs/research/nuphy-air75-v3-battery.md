# NuPhy Air75 V3 battery reporting on Linux

Date: 2026-07-16

## Conclusion

Do **not** add a 2.4 GHz Air75 V3 battery helper to Waybar yet. On this host, the attached NuPhy Air75 V3 dongle (`19f5:2620`) does not expose battery state through Linux `power_supply`, UPower, or a standard HID battery usage. It does expose an otherwise undocumented 64-byte bidirectional raw-HID channel, but I found no published NuPhy protocol, first-party CLI/API, or maintained open-source Air75 V3 implementation that defines a safe battery query for that channel.

Bluetooth is the practical fallback to test: BlueZ has a standard read-only `org.bluez.Battery1.Percentage` property and UPower supports Bluetooth LE batteries exported through that interface. Whether the **Air75 V3 itself** publishes that property must still be verified on this machine after a user-approved Bluetooth pairing; it is not currently paired and no connection changes were made during this research.

## Host observations (read-only)

These observations were made with the keyboard active through its 2.4 GHz dongle. They are local evidence, not claims about other NuPhy models or firmware versions.

- USB/HID identity: `NuPhy Air75 V3 Dongle`, VID:PID `19f5:2620`, unique string `NuPhy Keybord 0720`.
- Linux binds four HID interfaces to `hid-generic`.
- The four report descriptors contain:
  - a normal boot-style keyboard interface;
  - an NKRO keyboard interface;
  - mouse/system-control/consumer-control reports;
  - one non-standard channel with a 64-byte input report and a 64-byte output report.
- None of the descriptors contains a standard battery-strength usage.
- No NuPhy `power_supply` node exists below the HID devices or in the system power-supply view.
- `upower --dump` (UPower 1.91.3) lists the laptop battery and line-power devices only; it has no NuPhy keyboard/peripheral entry.
- The corresponding hidraw nodes were `/dev/hidraw4` through `/dev/hidraw7` at inspection time and were `0600 root:root`. A future userspace helper would need a narrowly scoped udev rule and must discover the correct interface dynamically; hidraw numbers are not stable.

This proves that a helper cannot get dongle battery state by merely reading sysfs or UPower. The 64-byte channel makes a proprietary query technically plausible, but it does not identify the request opcode, reply format, accuracy, sleeping/offline behavior, or whether a query has side effects.

## What NuPhy publishes

- NuPhy specifies Air75 V3 as tri-mode (2.4 GHz, USB-C, Bluetooth 5.0), with a 4,000 mAh battery and up to 1,200 hours with lighting off. Its official product page advertises a physical battery indicator, but does not document an operating-system battery API or HID report. [NuPhy Air75 V3 product page](https://nuphy.com/products/nuphy-air75-v3)
- NuPhy's official firmware page routes Air75 V3 to **NuPhyIO**, while routing Air75 V2 to **QMK firmware**. This is the clearest first-party warning not to reuse V2/QMK protocol assumptions for V3. [NuPhy firmware page](https://nuphy.com/pages/firmware)
- NuPhyIO's official device list includes Air75 V3 ANSI, ISO, and JIS, but its public manuals do not describe battery commands, a WebHID packet format, or a CLI/API. [NuPhyIO device list](https://www.nuphy.io/en-US), [NuPhyIO keyboard manuals](https://www.nuphy.io/en-US/keyboardDescription)
- NuPhy's public QMK fork contains `air75_v2` but not `air75_v3`; the V3 protocol therefore cannot be derived from the published V2 firmware as if it were the same product. [NuPhy QMK device tree](https://github.com/nuphy-src/qmk_firmware/tree/nuphy-keyboards/keyboards/nuphy)
- Air75 HE is a separate, wired-only magnetic-switch keyboard. It has neither a 2.4 GHz dongle nor a wireless battery to query. [NuPhy Air75 HE product page](https://nuphy.com/products/nuphy-air75-he-magnetic-switch-gaming-keyboard)

I found no first-party NuPhyIO source repository, documented WebHID protocol, command-line client, or maintained open-source utility that specifically implements an Air75 V3 battery query. Tools and firmware for the original Air75, Air75 V2, or Air75 HE are not evidence for VID:PID `19f5:2620`.

## Connection matrix

| Connection | Linux-visible battery now? | Query surface | Confidence |
|---|---:|---|---|
| Air75 V3 2.4 GHz dongle (`19f5:2620`) | No | No `power_supply` or UPower device. Only an undocumented 64-byte raw-HID IN/OUT channel. | High for “not standard/exposed”; low for any proprietary query. |
| Air75 V3 Bluetooth | Not tested on this host | If the keyboard exports BlueZ `org.bluez.Battery1`, read its `Percentage` property directly or through UPower. | High for the Linux API; medium/unknown for this exact keyboard and firmware. |
| Air75 V3 wired USB | Not investigated as a battery source | V3 remains a NuPhyIO device; no published battery protocol found. | Low/unknown. |
| Air75 V2 | Out of scope and not protocol-compatible evidence | Official NuPhy QMK source exists for V2. | High that V2 and V3 must not be conflated. |
| Air75 HE | Not applicable | Officially wired only. | High. |

## Bluetooth fallback

BlueZ defines `org.bluez.Battery1.Percentage` as a read-only unsigned 8-bit percentage on the Bluetooth device object. [BlueZ Battery API](https://github.com/bluez/bluez/blob/master/doc/org.bluez.Battery.rst)

UPower added Bluetooth LE battery support specifically for battery data exported by BlueZ's `org.bluez.Battery1`; current UPower can then enumerate and monitor that peripheral alongside other power devices. [UPower upstream change history](https://git.baserock.org/cgit/delta/upower.git/log/?h=wip%2Fhadess%2Fidevice-charge&showmsg=1), [UPower command documentation](https://upower.freedesktop.org/docs/upower.1.html)

Therefore Bluetooth + UPower is a viable architecture **if and only if** a live Air75 V3 connection produces either:

- `/org/bluez/.../dev_...` with `org.bluez.Battery1`, or
- a corresponding keyboard/Bluetooth device in `upower --dump`.

That is a short, non-destructive verification to perform after the user chooses to pair/switch the keyboard. If neither appears, Bluetooth does not solve the problem for that firmware and no Waybar-side formatting can manufacture the missing data.

## Recommended next step

Keep this out of the current Waybar integration. In a separate, explicitly approved hardware/protocol session, choose one of:

1. **Bluetooth validation first (recommended):** pair/switch the Air75 V3, then inspect BlueZ `Battery1` and `upower --dump`. If present, the Waybar work is straightforward and uses maintained system APIs.
2. **2.4 GHz reverse engineering:** capture the read-only NuPhyIO transaction that obtains status (if NuPhyIO displays battery), identify the exact 64-byte request/reply, confirm it across sleep/wake and firmware versions, and only then design a least-privilege hidraw helper. This is materially more work and carries protocol/firmware stability risk.

Do not poll arbitrary 64-byte requests, reuse V2 QMK commands, use a hard-coded `/dev/hidrawN`, or grant broad access to every NuPhy hidraw interface.

## Unknowns

- Whether NuPhyIO actually requests and displays numeric V3 battery state over the dongle, rather than only configuring the keyboard's on-device indicator.
- The proprietary request opcode, response layout, percentage precision, event/poll model, and behavior while the keyboard sleeps.
- Whether current Air75 V3 Bluetooth firmware exposes the standard GATT Battery Service/BlueZ `Battery1`.
- Whether wired USB and the 2.4 GHz dongle use the same status protocol.
