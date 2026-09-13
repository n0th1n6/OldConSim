// Vendor ESP32-2432S032 wiring, with a conservative 40 MHz write clock.
#define ST7789_DRIVER
#define TFT_WIDTH 240
#define TFT_HEIGHT 320
#define TFT_RGB_ORDER TFT_BGR
#define TFT_MISO 12
#define TFT_MOSI 13
#define TFT_SCLK 14
#define TFT_CS 15
#define TFT_DC 2
#define TFT_RST -1
// TFT reset is tied to the ESP32 reset/enable net on this board.
// Backlight is managed by the emulator's PWM on GPIO27.
#define TOUCH_CS 33
#define LOAD_GLCD
#define LOAD_FONT2
#define SPI_FREQUENCY 40000000
#define SPI_READ_FREQUENCY 20000000
#define SPI_TOUCH_FREQUENCY 2500000
#define USE_HSPI_PORT
