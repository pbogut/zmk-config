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

The dongle starts with USB preferred and Bluetooth profile 0 selected on every
boot. Output toggles and profile changes stay in RAM and do not write to flash.
Laptop and split pairings are still saved. Previously saved output/profile
selections are ignored, so installing this firmware needs no settings reset.

The dongle sends keystrokes to one selected output at a time. If the selected
Bluetooth profile is disconnected, ZMK falls back to USB even with Bluetooth
preferred. A laptop can remain connected on a profile that is not selected;
use ZMK + Q followed by ZMK + `.` to return to the laptop on profile 0.

## Battery levels over USB

The dongle exposes a dedicated USB CDC ACM serial port with both halves' battery
percentages. `custom_modules/battery_usb` implements this, enabled by
`CONFIG_ZMK_BATTERY_USB=y` in `config/kyria_dongle.conf`. The option also enables
ZMK's peripheral battery fetching. The Makefile and GitHub Actions load the module.

Build and flash only the dongle:

```sh
devbox run -- make build_kyria_dongle
```

Double-tap the dongle's reset button, then copy
`kyria_dongle-nice_nano_v2-zmk.uf2` to its `NICENANO` drive, or run
`make copy_kyria_dongle`. No settings reset or half reflash is needed.

### Reading on Linux

The serial port appears as `/dev/ttyACM*`. Find the dongle's stable device path:

```sh
ls -l /dev/serial/by-id/
```

Use that path below. This command streams one JSON object per line using `jq`:

```sh
port=/dev/serial/by-id/usb-REPLACE_WITH_YOUR_DONGLE
stty -F "$port" 115200 raw -echo -ixon -ixoff -crtscts clocal
jq --unbuffered -Rrc 'fromjson? | select(type == "object" and has("peripherals"))' < "$port"
```

The baud rate does not control USB transfer speed. The reader must assert DTR,
which normal Linux serial opens do. For permission errors, grant your user serial
access through your distribution's serial-device group, commonly `dialout` or
`uucp`, or a device-specific udev rule. Reopen the reader after unplugging the
dongle, using the same `/dev/serial/by-id/` path.

Example output:

```json
{"peripherals":[{"slot":0,"percent":82},{"slot":1,"percent":67}]}
```

- A snapshot arrives within about one second of detecting an open port, then
  every five seconds while it remains open and USB is active.
- `percent` is an integer from 0 to 100, or `null` until the slot has received a
  battery event since the dongle booted.
- The pinned ZMK version sends `0` when a half disconnects. That is indistinguishable
  from a real 0% reading in its battery events. A reconnect refreshes the reading.
- These are cached values. Repeating them over USB does not poll the halves again.
  The halves retain their existing 60-second active sampling interval and notify
  the dongle when the percentage changes.
- Blank lines separate snapshots. The stream is best-effort: a stalled reader
  can cause the bounded USB buffer to discard bytes. Ignore blank or malformed
  lines and resume at the next complete JSON object, as the command above does.

The port carries battery data only. It also works while the dongle sends keyboard
output to its Bluetooth host, provided USB remains connected to the Linux computer.

### Identifying left and right

Slots follow saved pairing order, not physical side. To identify them, turn both
halves off, restart the dongle, then power on only the left half. The slot that
changes from `null` to a number is left. Power on the right half to confirm the
other slot, and use that mapping in your reader.

The mapping survives half and dongle reboots, reconnect order changes, and normal
firmware updates. Clearing the dongle's split pairing settings and pairing again
can change it.

To check on hardware after flashing, verify readings with each half powered in
turn, open the reader after the keyboard has already connected, and unplug and
reconnect USB. Check typing and encoders with the reader open and closed.

## Local ZMK patches

`patch/volatile_output_selection.patch` adds two options to ZMK. They default to
`y`, preserving upstream behavior for other keyboards. The dongle disables both
in `config/kyria_dongle.conf`:

```ini
CONFIG_ZMK_OUTPUT_SELECTION_PERSISTENCE=n
CONFIG_ZMK_BLE_PROFILE_SELECTION_PERSISTENCE=n
```

Apply the patches to an existing checkout and build the dongle:

```sh
devbox run -- make patch
devbox run -- make build_kyria_dongle
```

`make patch` also applies the existing nice!view patch and skips patches already
applied. Kyria build targets run it automatically. `make init` applies both after
fetching a fresh workspace. `make update` removes applied patches, updates ZMK,
then reapplies them. `helper.sh init` and `helper.sh update` use these same targets.
GitHub Actions applies both patches before compiling too.

To run `west update` manually, use this order inside your build environment:

```sh
make unpatch
west update
west zephyr-export
make patch
```

To apply only the selection patch manually, from the repository root:

```sh
git -C zmk apply "$PWD/patch/volatile_output_selection.patch"
```

The patches target the revision in `config/west.yml`. If an upstream update
changes the affected code, patch application stops with an error so the patch
can be adjusted. Newer Zephyr versions provide `west patch`, but the Zephyr
checkout used here does not include that extension.

To check the new behavior on hardware, select Bluetooth and another profile,
wait more than 60 seconds, then power-cycle the dongle. It should use USB and
profile 0 again, and the halves and laptop should retain their pairings. Only
the dongle needs reflashing for this patch. USB reconnection without a power
cycle, such as with a battery-powered dongle, does not reset the selections.

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
