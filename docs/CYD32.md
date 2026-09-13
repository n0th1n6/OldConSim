# OldConSim: 3.2-inch CYD

Target: **ESP32-2432S032**, the 3.2-inch ESP32-32E board with a 240x320
ST7789 display and XPT2046 resistive touch. The board uses a classic dual-core
ESP32 and 4 MB flash. The model, resolution, and touch type are printed on the
PCB shown during bring-up.

OldConSim uses the panel in 320x240 landscape at rotation 3, matching the
vendor's flipped-landscape example. The NES image remains 256x240 and is
centered at (32, 0), so no larger framebuffer is required. The display starts
at a conservative 40 MHz and the SD card at 4 MHz.

## Vendor references

Source: <https://pan.jczn1688.com/1/ESP32%20module#/>

All 12 archives in the vendor's ESP32 module folder were downloaded on
2026-09-13 into `../CYD FIles/`. Original filenames are preserved. Vendor
manifests and `SHA256SUMS.txt` are alongside them; each downloaded shard was
checked against its vendor SHA-256 and byte count.

The board files are in `3.2inch_ESP32-2432S032.zip`. The configuration was
checked against the archive's TFT_eSPI setup, XPT2046 example, and schematics:

- `1-Demo/Demo_Arduino/7_1LvglMusic3.2_xpt2046/`
- `5-Schematic/ESP32-2432S032-LCM-V1.0 .jpg`
- `5-Schematic/ESP32-2432S032-MCU-V1.0 .jpg`

The vendor TFT setup allows an 80 MHz write clock. OldConSim initially uses
40 MHz for display stability. The vendor references remain outside this Git
repository.

## Built-in wiring

| Function | GPIO / setting |
| --- | --- |
| TFT driver / dimensions | ST7789, 240x320 portrait; rotation 3 |
| TFT SPI host | HSPI |
| TFT MOSI / MISO / clock | 13 / 12 / 14 |
| TFT CS / DC / reset | 15 / 2 / board reset (`-1`) |
| Backlight | GPIO27, active high |
| microSD SPI host | VSPI |
| microSD MOSI / MISO / clock / CS | 23 / 19 / 18 / 5 |
| Audio | DAC GPIO26; GPIO4 low enables the onboard amplifier |
| Resistive touch | XPT2046 on TFT SPI, CS33, IRQ36 |
| USB controller input | Onboard USB-to-serial, 115200 baud |

Touch is not used for game input yet. TFT_eSPI keeps touch CS inactive while
using the display. No NES/SNES/PSX or separate UART controller wiring is
assigned by this profile. GPIO27 drives the backlight, so Serial1 is disabled.

## Build

The wrapper locates the repository and supports setup, build, port discovery,
flash, and combined build/flash commands. Install Arduino CLI 1.4.1 and put
`arduino-cli` on PATH, or set `ARDUINO_CLI` to its executable path.

Install the pinned dependencies and perform the first build:

```sh
./scripts/cyd32.sh setup
```

This installs ESP32 Arduino core **3.2.1**, TFT_eSPI **2.5.43**, and SdFat
**2.3.0**, then builds. Packages and the customized display setup are isolated
in `/tmp/oldconsim-arduino/`, leaving system Arduino installations untouched.
This cache must reside on a filesystem that supports hard links. Set
`OLDCONSIM_ARDUINO_ROOT` to another local cache directory if desired.

Subsequent builds:

```sh
./scripts/cyd32.sh build
```

The script stages the sketch in a temporary `Anemoia-ESP32` directory because
Arduino requires the sketch directory to match the `.ino` filename. Outputs
are written to `build/cyd32/`. The `OLDCONSIM_CYD32` define selects
`config_cyd32.h` and `User_Setups/CYD32/User_Setup.h`. This profile uses its
compiled hardware defaults instead of a stale WebFlash hardware configuration.

## Flash

Close any serial monitor or controller using the port. Then list devices and
pass the selected serial device explicitly:

```sh
./scripts/cyd32.sh ports
./scripts/cyd32.sh -p /dev/cu.usbserial-REPLACE_ME flash
```

To rebuild immediately before flashing:

```sh
./scripts/cyd32.sh -p /dev/cu.usbserial-REPLACE_ME build-flash
```

The wrapper flashes and verifies the bootloader, partition table, boot-app
image, and application without erasing the entire flash. Upload speed defaults
to 115200 because this board's serial path returned corrupt packets at 460800
and 921600. Override a proven connection with `OLDCONSIM_UPLOAD_SPEED`.

## SD card and first hardware checks

The microSD socket is required: an empty socket produces `SD Init Failed` and
`Insert SD`. Use a known-good FAT32 card and place `.nes` files in its root
directory. OldConSim initializes this board's separate VSPI SD bus at 4 MHz,
which is already substantially lower than the original 20 MHz setting.

After flashing, verify boot, backlight, orientation, colors, SD loading,
centered game rendering, USB input, speaker audio, and pause/resume. Start +
Select opens the pause menu. Touch controls and standalone physical controller
wiring are future work. A successful build and verified flash do not prove
display, SD, input, or audio behavior on the physical board.

The upstream source and GPLv3 license are retained.

## Build verification

`build/cyd32/BUILD-INFO.txt` records the tool versions, binary sizes, and
SHA-256 hashes for the latest local build.
