#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat >&2 <<'USAGE'
Usage: scripts/cyd32.sh [options] <command>

Commands:
  setup        Install the pinned Arduino dependencies, then build
  build        Build firmware for the 3.2-inch ESP32-2432S032
  flash        Flash the existing build and verify it
  build-flash  Build, flash, and verify
  ports        List connected boards and serial ports

Options:
  -p, --port DEVICE  Serial device required by flash/build-flash

Examples:
  ./scripts/cyd32.sh setup
  ./scripts/cyd32.sh build
  ./scripts/cyd32.sh ports
  ./scripts/cyd32.sh -p /dev/cu.usbserial-XXXX flash
  ./scripts/cyd32.sh -p /dev/cu.usbserial-XXXX build-flash
USAGE
    exit 2
}

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$repo_dir/build/cyd32"
build_script="$repo_dir/scripts/build-cyd32.sh"
toolchain_dir="${OLDCONSIM_ARDUINO_ROOT:-/tmp/oldconsim-arduino}"
upload_speed="${OLDCONSIM_UPLOAD_SPEED:-115200}"
fqbn="esp32:esp32:esp32:PartitionScheme=custom,EventsCore=0,UploadSpeed=$upload_speed"

resolve_cli() {
    if [[ -n "${ARDUINO_CLI:-}" ]]; then
        printf '%s\n' "$ARDUINO_CLI"
    elif command -v arduino-cli >/dev/null 2>&1; then
        command -v arduino-cli
    elif [[ -x /private/tmp/oldconsim-tools/arduino-cli ]]; then
        printf '%s\n' /private/tmp/oldconsim-tools/arduino-cli
    else
        echo 'arduino-cli is unavailable.' >&2
        echo 'Install Arduino CLI 1.4.1 or set ARDUINO_CLI to its executable.' >&2
        exit 1
    fi
}

port=''
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--port)
            [[ $# -ge 2 ]] || usage
            port="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage
            ;;
        *)
            break
            ;;
    esac
done

[[ $# -eq 1 ]] || usage
command_name="$1"
cli="$(resolve_cli)"

build_firmware() {
    ARDUINO_CLI="$cli" \
    OLDCONSIM_ARDUINO_ROOT="$toolchain_dir" \
        "$build_script"
}

flash_firmware() {
    if [[ -z "$port" ]]; then
        echo 'A serial device is required for flashing.' >&2
        echo "Run '$0 ports', then pass it with -p or --port." >&2
        exit 2
    fi

    local artifact
    for artifact in \
        Anemoia-ESP32.ino.bootloader.bin \
        Anemoia-ESP32.ino.partitions.bin \
        Anemoia-ESP32.ino.bin; do
        if [[ ! -f "$build_dir/$artifact" ]]; then
            echo "Missing build artifact: $build_dir/$artifact" >&2
            echo "Run '$0 build' first, or use '$0 -p $port build-flash'." >&2
            exit 1
        fi
    done

    export ARDUINO_DIRECTORIES_DATA="$toolchain_dir/data"
    export ARDUINO_DIRECTORIES_DOWNLOADS="$toolchain_dir/downloads"
    export ARDUINO_DIRECTORIES_USER="$toolchain_dir/user"
    export ARDUINO_BOARD_MANAGER_ADDITIONAL_URLS=https://espressif.github.io/arduino-esp32/package_esp32_index.json

    "$cli" upload \
        --verify \
        --fqbn "$fqbn" \
        --port "$port" \
        --input-dir "$build_dir"
}

case "$command_name" in
    setup)
        ARDUINO_CLI="$cli" \
        OLDCONSIM_ARDUINO_ROOT="$toolchain_dir" \
            "$build_script" --setup
        ;;
    build)
        build_firmware
        ;;
    flash)
        flash_firmware
        ;;
    build-flash)
        build_firmware
        flash_firmware
        ;;
    ports)
        "$cli" board list
        ;;
    *)
        echo "Unknown command: $command_name" >&2
        usage
        ;;
esac
