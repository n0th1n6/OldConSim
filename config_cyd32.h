#ifndef CONFIG_CYD32_H
#define CONFIG_CYD32_H

// ESP32-2432S032, ST7789 240x320. See docs/CYD32.md.
#include "config_cyd.h"

#undef TFT_BACKLIGHT_PIN
#define TFT_BACKLIGHT_PIN 27

// The vendor's resistive-touch example uses landscape rotation 3.
#undef SCREEN_ROTATION
#define SCREEN_ROTATION 3

// Conservative bring-up clock. Raise only after the card is reliable.
#undef SD_FREQ
#define SD_FREQ 4000000

// GPIO26 supplies DAC audio; GPIO4 enables the onboard amplifier when low.
#define AUDIO_AMP_ENABLE_PIN 4
#define AUDIO_AMP_ENABLE_LEVEL LOW

// USB serial controller only: the UART TX pin conflicts with the backlight.
#define CONTROLLER_USB_SERIAL_ONLY
#undef CONTROLLER_UART_TX
#undef CONTROLLER_UART_RX
#define CONTROLLER_UART_TX -1
#define CONTROLLER_UART_RX -1

// No direct wired controller pinout is assigned for this board yet.
#undef CONTROLLER_NES_CLK
#undef CONTROLLER_NES_LATCH
#undef CONTROLLER_NES_DATA
#define CONTROLLER_NES_CLK -1
#define CONTROLLER_NES_LATCH -1
#define CONTROLLER_NES_DATA -1

// Do not let an old WebFlash config override this board's bring-up settings.
#define USE_COMPILED_RUNTIME_CONFIG

#endif
