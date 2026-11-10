#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include <Fonts/FreeSansBold9pt7b.h>

#define PANEL_RES_X 128
#define PANEL_RES_Y 64
#define PANEL_CHAIN 1

// ================== BUTTONS ==================
const int BTN_A = 12;  // Player 1 +
const int BTN_B = 13;  // Player 2 +
const int BTN_C = 14;  // Reset (long press)

const unsigned long LONG_PRESS_MS = 600;

unsigned long pressStart[3] = {0, 0, 0};
bool wasPressed[3] = {false, false, false};
int buttons[3] = {BTN_A, BTN_B, BTN_C};

// ================== SCORE ==================
int scorePlayerOne = 0;
int scorePlayerTwo = 0;

// ================== HUB75 PIN MAP ==================
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
MatrixPanel_I2S_DMA *dma_display = nullptr;


// ================== DRAW FUNCTION ==================
void drawScoreboard() {

  dma_display->clearScreen();
  dma_display->setFont(&FreeSansBold9pt7b);
  dma_display->setTextWrap(false);

  int16_t x1, y1;
  uint16_t w, h;

  int left_margin = 6;
  int right_margin = 6;

  // Divider line
  dma_display->drawFastHLine(0, 34, 128, dma_display->color565(40,40,40));

  // ----- PLAYER 2 (TOP / GREEN) -----
  dma_display->setTextColor(dma_display->color565(0,255,0));
  dma_display->setCursor(left_margin, 26);
  dma_display->print("PLAYER 2");

  String s1 = String(scorePlayerTwo);
  dma_display->getTextBounds(s1,0,0,&x1,&y1,&w,&h);
  dma_display->setCursor(PANEL_RES_X - w - right_margin, 26);
  dma_display->print(s1);


  // ----- PLAYER 1 (BOTTOM / BLUE) -----
  dma_display->setTextColor(dma_display->color565(0,0,255));
  dma_display->setCursor(left_margin, 54);
  dma_display->print("PLAYER 1");

  String s2 = String(scorePlayerOne);
  dma_display->getTextBounds(s2,0,0,&x1,&y1,&w,&h);
  dma_display->setCursor(PANEL_RES_X - w - right_margin, 54);
  dma_display->print(s2);
}


// ================== SETUP ==================
void setup() {

  Serial.begin(115200);

  // Setup buttons
  for (int i = 0; i < 3; i++) {
    pinMode(buttons[i], INPUT_PULLUP);
  }

  // Display config
  mxconfig.driver = HUB75_I2S_CFG::ICN2038S;
  mxconfig.clkphase = false;
  mxconfig.latch_blanking = true;

  dma_display = new MatrixPanel_I2S_DMA(mxconfig);
  dma_display->begin();
  dma_display->setBrightness8(140);

  drawScoreboard();
}


// ================== LOOP ==================
void loop() {

  for (int i = 0; i < 3; i++) {

    bool pressed = digitalRead(buttons[i]) == LOW;

    // ===== BUTTON JUST PRESSED =====
    if (pressed && !wasPressed[i]) {
      pressStart[i] = millis();
      wasPressed[i] = true;
    }

    // ===== BUTTON JUST RELEASED =====
    if (!pressed && wasPressed[i]) {

      unsigned long duration = millis() - pressStart[i];

      // ===== PLAYER 1 BUTTON =====
      if (i == 0) {
        if (duration >= LONG_PRESS_MS) {
          if (scorePlayerOne > 0) scorePlayerOne--;
        } else {
          scorePlayerOne++;
        }
      }

      // ===== PLAYER 2 BUTTON =====
      if (i == 1) {
        if (duration >= LONG_PRESS_MS) {
          if (scorePlayerTwo > 0) scorePlayerTwo--;
        } else {
          scorePlayerTwo++;
        }
      }

      // ===== RESET BUTTON =====
      if (i == 2) {
        if (duration >= LONG_PRESS_MS) {
          scorePlayerOne = 0;
          scorePlayerTwo = 0;
        }
      }

      drawScoreboard();

      wasPressed[i] = false;

      // debounce
      delay(20);
    }
  }
}