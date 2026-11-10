#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include <Fonts/FreeSansBold9pt7b.h>

// ============================================================
// ESP32-S3 HUB75 Scoreboard
// ============================================================

// ================== SCOREBOARD CONFIG ==================
const char* PLAYER_ONE_NAME = "PLAYER 1";
const char* PLAYER_TWO_NAME = "PLAYER 2";

#define PANEL_RES_X 128
#define PANEL_RES_Y 64
#define PANEL_CHAIN 1

const uint8_t DISPLAY_BRIGHTNESS = 140;
const unsigned long LONG_PRESS_MS = 600;

// ================== BUTTONS ==================
// Player One and Player Two:
//   short press = +1
//   long press  = -1
// Reset:
//   long press  = reset both scores
const int BTN_PLAYER_ONE = 12;
const int BTN_PLAYER_TWO = 13;
const int BTN_RESET = 14;

const int buttons[3] = {BTN_PLAYER_ONE, BTN_PLAYER_TWO, BTN_RESET};
unsigned long pressStart[3] = {0, 0, 0};
bool wasPressed[3] = {false, false, false};

// ================== SCORE ==================
int scorePlayerOne = 0;
int scorePlayerTwo = 0;

// ================== HUB75 PIN MAP ==================
// Working ESP32-S3 -> HUB75 adapter mapping for this build.
HUB75_I2S_CFG::i2s_pins pins = {
  6,   // R1
  36,  // G1
  37,  // B1
  5,   // R2
  0,   // G2
  35,  // B2
  45,  // A
  1,   // B
  48,  // C
  2,   // D
  4,   // E
  38,  // LAT
  21,  // OE
  47   // CLK
};

HUB75_I2S_CFG mxconfig(PANEL_RES_X, PANEL_RES_Y, PANEL_CHAIN, pins);
MatrixPanel_I2S_DMA* dma_display = nullptr;

// ================== DRAW SCOREBOARD ==================
void drawScoreboard() {
  dma_display->clearScreen();
  dma_display->setFont(&FreeSansBold9pt7b);
  dma_display->setTextWrap(false);

  int16_t x1, y1;
  uint16_t w, h;

  const int leftMargin = 6;
  const int rightMargin = 6;

  // Divider between the two player rows.
  dma_display->drawFastHLine(
    0, 34, PANEL_RES_X, dma_display->color565(40, 40, 40)
  );

  // ----- PLAYER TWO: TOP / GREEN -----
  dma_display->setTextColor(dma_display->color565(0, 255, 0));
  dma_display->setCursor(leftMargin, 26);
  dma_display->print(PLAYER_TWO_NAME);

  String s2 = String(scorePlayerTwo);
  dma_display->getTextBounds(s2, 0, 0, &x1, &y1, &w, &h);
  dma_display->setCursor(PANEL_RES_X - w - rightMargin, 26);
  dma_display->print(s2);

  // ----- PLAYER ONE: BOTTOM / BLUE -----
  dma_display->setTextColor(dma_display->color565(0, 0, 255));
  dma_display->setCursor(leftMargin, 54);
  dma_display->print(PLAYER_ONE_NAME);

  String s1 = String(scorePlayerOne);
  dma_display->getTextBounds(s1, 0, 0, &x1, &y1, &w, &h);
  dma_display->setCursor(PANEL_RES_X - w - rightMargin, 54);
  dma_display->print(s1);
}

// ================== SETUP ==================
void setup() {
  Serial.begin(115200);

  for (int i = 0; i < 3; i++) {
    pinMode(buttons[i], INPUT_PULLUP);
  }

  mxconfig.driver = HUB75_I2S_CFG::ICN2038S;
  mxconfig.clkphase = false;
  mxconfig.latch_blanking = true;

  dma_display = new MatrixPanel_I2S_DMA(mxconfig);
  dma_display->begin();
  dma_display->setBrightness8(DISPLAY_BRIGHTNESS);

  drawScoreboard();
}

// ================== LOOP ==================
void loop() {
  for (int i = 0; i < 3; i++) {
    bool pressed = digitalRead(buttons[i]) == LOW;

    // Button just pressed.
    if (pressed && !wasPressed[i]) {
      pressStart[i] = millis();
      wasPressed[i] = true;
    }

    // Button just released.
    if (!pressed && wasPressed[i]) {
      unsigned long duration = millis() - pressStart[i];

      // Player One button.
      if (i == 0) {
        if (duration >= LONG_PRESS_MS) {
          if (scorePlayerOne > 0) scorePlayerOne--;
        } else {
          scorePlayerOne++;
        }
      }

      // Player Two button.
      if (i == 1) {
        if (duration >= LONG_PRESS_MS) {
          if (scorePlayerTwo > 0) scorePlayerTwo--;
        } else {
          scorePlayerTwo++;
        }
      }

      // Reset button: long press only.
      if (i == 2 && duration >= LONG_PRESS_MS) {
        scorePlayerOne = 0;
        scorePlayerTwo = 0;
      }

      drawScoreboard();
      wasPressed[i] = false;

      // Simple release debounce.
      delay(20);
    }
  }
}
