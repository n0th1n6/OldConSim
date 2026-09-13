#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
cli="${ARDUINO_CLI:-arduino-cli}"
# Isolate board packages and customized TFT_eSPI from other Arduino projects.
# The toolchain requires hard links, which exFAT workspaces do not support.
# Use a native local filesystem; override this path for a persistent cache.
toolchain_dir="${OLDCONSIM_ARDUINO_ROOT:-/tmp/oldconsim-arduino}"
export ARDUINO_DIRECTORIES_DATA="$toolchain_dir/data"
export ARDUINO_DIRECTORIES_DOWNLOADS="$toolchain_dir/downloads"
export ARDUINO_DIRECTORIES_USER="$toolchain_dir/user"
export ARDUINO_BOARD_MANAGER_ADDITIONAL_URLS=https://espressif.github.io/arduino-esp32/package_esp32_index.json
if [[ "${1:-}" == "--setup" ]]; then
    "$cli" core update-index
    "$cli" core install esp32:esp32@3.2.1
    "$cli" lib install 'TFT_eSPI@2.5.43' 'SdFat@2.3.0'
elif [[ $# -ne 0 ]]; then
    echo 'Usage: scripts/build-cyd32.sh [--setup]' >&2
    exit 2
fi
platform_dir="$ARDUINO_DIRECTORIES_DATA/packages/esp32/hardware/esp32/3.2.1"
library_dir="$ARDUINO_DIRECTORIES_USER/libraries/TFT_eSPI"
if [[ ! -d "$platform_dir" || ! -d "$library_dir" ]]; then
    echo 'Install dependencies first: scripts/build-cyd32.sh --setup' >&2
    exit 1
fi
cp "$repo_dir/platform.txt" "$platform_dir/platform.txt"
cp "$repo_dir/User_Setups/CYD32/User_Setup.h" "$library_dir/User_Setup.h"
# Arduino requires the sketch folder to match its .ino filename.
# Stage current sources in a fresh directory to avoid stale copied source files.
sketch_parent="$(mktemp -d "${TMPDIR:-/tmp}/oldconsim-sketch.XXXXXX")"
trap 'rm -rf "$sketch_parent"' EXIT
sketch_dir="$sketch_parent/Anemoia-ESP32"
intermediate_dir="$sketch_parent/build"
mkdir -p "$sketch_dir" "$repo_dir/build/cyd32"
cp "$repo_dir/Anemoia-ESP32.ino" "$repo_dir/partitions.csv" "$repo_dir/"*.h "$sketch_dir/"
cp -R "$repo_dir/src" "$sketch_dir/src"
flags='-DOPTIMIZATION_FLAGS -DOLDCONSIM_CYD32 -Ofast -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -funroll-loops -fno-tree-vectorize -frename-registers -fno-plt -flto'
"$cli" compile --fqbn 'esp32:esp32:esp32:PartitionScheme=custom,EventsCore=0' \
    --build-property "compiler.cpp.extra_flags=$flags" \
    --build-property "compiler.c.extra_flags=$flags" \
    --build-path "$intermediate_dir" \
    --output-dir "$repo_dir/build/cyd32" "$sketch_dir"

app_binary="$repo_dir/build/cyd32/Anemoia-ESP32.ino.bin"
merged_binary="$repo_dir/build/cyd32/Anemoia-ESP32.ino.merged.bin"
build_info="$repo_dir/build/cyd32/BUILD-INFO.txt"
{
    printf '%s\n' \
        'OldConSim ESP32-2432S032 resistive-touch build' \
        'Arduino CLI: 1.4.1' \
        'ESP32 Arduino core: 3.2.1' \
        'TFT_eSPI: 2.5.43' \
        'SdFat: 2.3.0' \
        'Target: classic ESP32, 4 MB flash, ST7789 320x240 landscape' \
        "App binary: $(stat -f '%z' "$app_binary") bytes" \
        'App partition: 1310720 bytes' \
        "Merged image: $(stat -f '%z' "$merged_binary") bytes" \
        '' \
        'SHA-256:'
    (
        cd "$repo_dir/build/cyd32"
        LC_ALL=C LANG=C shasum -a 256 ./*.bin | sed 's|  \./|  |'
    )
} > "$build_info"
