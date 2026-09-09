# Kyria with a dongle

The Kyria uses three nice!nano v2 controllers. Both keyboard halves are BLE
peripherals. The dongle runs `config/kyria.keymap` and connects to a computer
over USB or Bluetooth.

```text
Kyria left  --BLE--+
                  +-- nice!nano dongle --USB-- Desktop
Kyria right --BLE--+                   --BLE-- Laptop
```

The dongle must stay powered, including when typing on the laptop over Bluetooth.
The halves cannot connect directly to a computer in this configuration.

Displays are disabled and the builds omit the nice!view shields. The display
settings remain commented out in `config/kyria.conf`, and the existing display
patch remains in `patch/`. Encoders are enabled on both halves.

## Build

Using the repository's Devbox environment:

```sh
devbox run -- make build_kyria build_kyria_settings_reset
```

Devbox initializes the local ZMK workspace on first use. With an existing ZMK
toolchain environment, run the same `make` command without `devbox run --`.
The Makefile requires GNU Make 4.4 or newer for `.WAIT`; Devbox provides it.

The build writes these files to the repository root:

| Firmware | Device |
| --- | --- |
| `kyria_left-nice_nano_v2-zmk.uf2` | Left half |
| `kyria_right-nice_nano_v2-zmk.uf2` | Right half |
| `kyria_dongle-nice_nano_v2-zmk.uf2` | Dongle |
| `kyria_settings_reset-nice_nano_v2-zmk.uf2` | Settings reset for any of the three nice!nano v2 boards |

Individual targets are `build_kyria_left`, `build_kyria_right`, and
`build_kyria_dongle`. Each has a separate directory under `build/`, containing
its generated `zephyr/.config` and `zephyr/zephyr.dts`.

`helper.sh build kyria` builds all three devices. Use `--left`, `--right`, or
`--dongle` to build just one. GitHub Actions builds the same four firmware images
from `build.yaml`.

## First flash and pairing

Changing the central requires clearing the old split bonds. A normal firmware
flash does not clear them.

1. Label the three boards so the left, right, and dongle firmware do not get mixed up.
2. Connect one board by USB and double-tap reset to enter its bootloader.
   It should appear as a `NICENANO` drive.
3. Copy `kyria_settings_reset-nice_nano_v2-zmk.uf2` onto that drive.
   Let the board reboot and run for a few seconds, then disconnect it.
4. Repeat the reset flash on the other two boards, so all three have cleared settings.
5. Enter the bootloader again on each board and flash its corresponding normal
   firmware from the table above. Flash one board at a time, letting it reboot
   and disconnecting it before connecting the next board.
6. Plug the dongle into the desktop and power on both halves. They pair with the
   dongle automatically. If they do not connect, restart all three together.
7. Test keys on both halves, cross-half combos, layer holds, and both encoders.

For a bootloader mounted at `/run/media/pbogut/NICENANO`, the Makefile provides
`copy_kyria_settings_reset`, `copy_kyria_left`, `copy_kyria_right`, and
`copy_kyria_dongle`. Run these individually for the board currently connected.
The `copy_` targets only copy existing firmware; the corresponding `flash_`
targets build first.

`copy_kyria` and `flash_kyria` process left, right, then dongle. The half-copy
targets wait for the bootloader drive to unmount after flashing before proceeding
to the next device.

If pairing remains broken, repeat the settings reset on all three devices and
then restore their normal firmware. The keymap's `BT_CLR` clears a host profile,
not the split bonds between the dongle and the halves.

## Desktop USB and laptop Bluetooth

The existing keymap is shared by all three builds. Host profiles belong to the
dongle now, so pair the laptop with **Kyria Dongle**. Old pairings with the left
half do not transfer.

Hold either inner thumb key labeled `ZMK` in `config/kyria.keymap` to access the
ZMK layer. Key names below refer to their positions on the base layer:

| Action | Keys |
| --- | --- |
| Select laptop Bluetooth profile 0 | Hold ZMK, press Q |
| Send output over Bluetooth | Hold ZMK, press `.` |
| Send output over USB | Hold ZMK, press `,` |
| Toggle USB/Bluetooth preference | Hold ZMK, press M |
| Clear the selected host Bluetooth profile | Hold ZMK, press F |

To pair the laptop, select profile 0 and add **Kyria Dongle** in the laptop's
Bluetooth settings. Then select Bluetooth output. To type on the desktop again,
select USB output. Selecting a Bluetooth profile alone does not switch output
away from USB while the dongle is plugged into the desktop.

USB is the initial preferred output. ZMK saves changes to that preference, so
use the explicit USB/Bluetooth keys if the output after a restart is unexpected.
The dongle sends keystrokes to one selected output at a time.

## Updating the keymap

For changes to layers, combos, macros, or ordinary key bindings, rebuild and
flash the dongle:

```sh
devbox run -- make build_kyria_dongle
```

Use the dongle's physical reset button to enter its bootloader. The existing
`&bootloader` and `&sys_reset` bindings act on the half where the key was pressed.
Changes to hardware, encoder configuration, layouts, or the ZMK version should
be built and flashed on all affected devices. Routine keymap updates do not
require a settings reset.

## Moving the dongle to a XIAO

The dongle shield has no GPIO assignments. The Makefile accepts
`KYRIA_DONGLE_BOARD` and `KYRIA_DONGLE_MOUNT` overrides for another controller.
Change the dongle entry in `build.yaml` too if you want GitHub Actions to build it.

Before migrating, use a ZMK version with a complete XIAO nRF52840 board
configuration. On the current pin, the raw Zephyr `xiao_ble` target compiles but
does not enable persistent settings storage. It needs the ZMK board defaults for
flash/NVS before it can retain Bluetooth bonds; a successful build alone is not
enough. The nice!nano v2 builds enable this storage already.

Use a XIAO-specific `settings_reset` build for the new dongle, then reset both
halves' settings and restore their firmware so they can bond to the new
controller. Pair the laptop with the new dongle as well.

The ZMK revision remains pinned in `config/west.yml`. The dongle's copied layouts
and transforms match that revision's `kyria_left`/`kyria_right` shields. Recheck
them against upstream when changing the ZMK pin or Kyria hardware revision.
