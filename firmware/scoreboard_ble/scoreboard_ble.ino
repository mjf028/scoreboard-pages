#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include <Fonts/FreeSansBold9pt7b.h>
#include <Preferences.h>

#define PANEL_RES_X 128
#define PANEL_RES_Y 64
#define PANEL_CHAIN 1

// ================== BUTTONS ==================
const int BTN_A = 12;  // Player 1 (bottom / blue)
const int BTN_B = 13;  // Player 2 (top / green)
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


void drawScoreboard();

// BLE additions: callbacks only enqueue commands or publish atomic flags.
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>
#include <atomic>

static const char *SERVICE_UUID = "ea180001-7444-4d8e-b83c-3f0c0e473ee1";
static const char *COMMAND_UUID = "ea180002-7444-4d8e-b83c-3f0c0e473ee1";
static const char *STATE_UUID   = "ea180003-7444-4d8e-b83c-3f0c0e473ee1";
static const char *NAMES_STATE_UUID = "ea180004-7444-4d8e-b83c-3f0c0e473ee1";
static const char *NAMES_WRITE_UUID = "ea180005-7444-4d8e-b83c-3f0c0e473ee1";
static constexpr size_t MAX_NAME_LENGTH = 8;
static constexpr size_t MAX_NAMES_PACKET = 2 * MAX_NAME_LENGTH + 2;

struct PlayerNames {
  char p1[MAX_NAME_LENGTH + 1];
  char p2[MAX_NAME_LENGTH + 1];
};

static PlayerNames playerNames = {"PLAYER 1", "PLAYER 2"};
static QueueHandle_t nameQueue;
static BLECharacteristic *namesState;
static Preferences nameStorage;
static bool nameStorageReady;

// P1 = bottom/blue (GPIO12); P2 = top/green (GPIO13).
enum BleCommand : uint8_t { P1_UP, P1_DOWN, P2_UP, P2_DOWN, SCORES_RESET };
static QueueHandle_t commandQueue;
static BLECharacteristic *scoreState;
static std::atomic<bool> bleConnected{false};
static std::atomic<bool> restartAdvertising{false};
static std::atomic<uint32_t> rejectedCommands{0};

class ScoreServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *) override { bleConnected.store(true); }
  void onDisconnect(BLEServer *) override {
    bleConnected.store(false);
    restartAdvertising.store(true);
  }
};
class ScoreCommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *characteristic) override {
    const String value = characteristic->getValue();
    BleCommand command;
    if (value == "P1+") command = P1_UP;
    else if (value == "P1-") command = P1_DOWN;
    else if (value == "P2+") command = P2_UP;
    else if (value == "P2-") command = P2_DOWN;
    else if (value == "RESET") command = SCORES_RESET;
    else { rejectedCommands.fetch_add(1); return; }
    // Never block the Bluetooth task. Overflow is counted and logged by loop().
    if (xQueueSend(commandQueue, &command, 0) != pdTRUE)
      rejectedCommands.fetch_add(1);
  }
};

// Name packets are ASCII: version '1', P1, '|', P2.
static bool decodePlayerNames(const uint8_t *data, size_t length, PlayerNames &names) {
  if (length < 4 || length > MAX_NAMES_PACKET || data[0] != '1') return false;

  PlayerNames decoded{};
  char *name = decoded.p1;
  size_t count = 0;
  for (size_t i = 1; i < length; ++i) {
    const uint8_t c = data[i];
    if (c == '|') {
      if (name != decoded.p1 || count == 0 || name[count - 1] == ' ') return false;
      name = decoded.p2;
      count = 0;
      continue;
    }
    const bool allowed = (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == ' ';
    if (!allowed || count == MAX_NAME_LENGTH || (count == 0 && c == ' ')) return false;
    name[count++] = c;
  }
  if (name != decoded.p2 || count == 0 || name[count - 1] == ' ') return false;
  names = decoded;
  return true;
}

class PlayerNamesCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *characteristic) override {
    PlayerNames requested;
    if (!decodePlayerNames(characteristic->getData(), characteristic->getLength(), requested)
        || xQueueSend(nameQueue, &requested, 0) != pdTRUE) {
      rejectedCommands.fetch_add(1);
    }
  }
};

static String encodePlayerNames(const PlayerNames &names) {
  return String('1') + names.p1 + '|' + names.p2;
}

static void publishPlayerNames(bool notifyClient) {
  namesState->setValue(encodePlayerNames(playerNames));
  if (notifyClient && bleConnected.load()) namesState->notify();
}

static void loadPlayerNames() {
  nameStorageReady = nameStorage.begin("scoreboard", false);
  if (!nameStorageReady || !nameStorage.isKey("names")) return;

  uint8_t data[MAX_NAMES_PACKET];
  const size_t length = nameStorage.getBytesLength("names");
  if (length <= sizeof(data) && nameStorage.getBytes("names", data, length) == length) {
    decodePlayerNames(data, length, playerNames);
  }
}

static void processPlayerNames() {
  PlayerNames requested;
  if (xQueueReceive(nameQueue, &requested, 0) != pdTRUE) return;

  if (strcmp(requested.p1, playerNames.p1) != 0 || strcmp(requested.p2, playerNames.p2) != 0) {
    const String value = encodePlayerNames(requested);
    if (!nameStorageReady || nameStorage.putBytes("names", value.c_str(), value.length()) != value.length()) {
      Serial.println("Could not save scoreboard player names");
      return;
    }
    playerNames = requested;
    drawScoreboard();
  }
  publishPlayerNames(true);
}

// Eight bytes: unsigned little-endian uint32 P1 followed by uint32 P2.
// Fits even the default ATT MTU; avoids truncated notifications at large scores.
void publishScoreState(bool notifyClient) {
  uint8_t value[8];
  const uint32_t p1 = static_cast<uint32_t>(scorePlayerOne);
  const uint32_t p2 = static_cast<uint32_t>(scorePlayerTwo);
  for (int i = 0; i < 4; ++i) {
    value[i] = (p1 >> (8 * i)) & 0xff;
    value[4 + i] = (p2 >> (8 * i)) & 0xff;
  }
  scoreState->setValue(value, sizeof(value));
  if (notifyClient && bleConnected.load()) scoreState->notify();
}
void setupScoreBle() {
  commandQueue = xQueueCreate(32, sizeof(BleCommand));
  nameQueue = xQueueCreate(1, sizeof(PlayerNames));
  if (!commandQueue || !nameQueue) {
    Serial.println("BLE command queue allocation failed");
    while (true) delay(1000);
  }
  BLEDevice::init("Scoreboard");
  BLEServer *server = BLEDevice::createServer();
  server->setCallbacks(new ScoreServerCallbacks());
  BLEService *service = server->createService(SERVICE_UUID);
  BLECharacteristic *command = service->createCharacteristic(
      COMMAND_UUID, BLECharacteristic::PROPERTY_WRITE);
  command->setCallbacks(new ScoreCommandCallbacks());
  scoreState = service->createCharacteristic(STATE_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  scoreState->addDescriptor(new BLE2902());
  namesState = service->createCharacteristic(NAMES_STATE_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  namesState->addDescriptor(new BLE2902());
  BLECharacteristic *namesWrite = service->createCharacteristic(
      NAMES_WRITE_UUID, BLECharacteristic::PROPERTY_WRITE);
  namesWrite->setCallbacks(new PlayerNamesCallbacks());
  publishPlayerNames(false);
  publishScoreState(false);
  service->start();
  BLEAdvertising *advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setScanResponse(true);
  advertising->start();
}
void processScoreBle() {
  static bool waitingToAdvertise = false;
  static unsigned long disconnectedAt = 0;
  if (restartAdvertising.exchange(false)) {
    waitingToAdvertise = true;
    disconnectedAt = millis();
  }
  if (waitingToAdvertise && millis() - disconnectedAt >= 500) {
    if (!bleConnected.load()) BLEDevice::startAdvertising();
    waitingToAdvertise = false;
  }
  // Bound each batch so a wireless burst cannot starve physical button polling.
  BleCommand command;
  for (int n = 0; n < 8 && xQueueReceive(commandQueue, &command, 0) == pdTRUE; ++n) {
    switch (command) {
      case P1_UP: if (scorePlayerOne < INT32_MAX) ++scorePlayerOne; break;
      case P1_DOWN: if (scorePlayerOne > 0) --scorePlayerOne; break;
      case P2_UP: if (scorePlayerTwo < INT32_MAX) ++scorePlayerTwo; break;
      case P2_DOWN: if (scorePlayerTwo > 0) --scorePlayerTwo; break;
      case SCORES_RESET: scorePlayerOne = 0; scorePlayerTwo = 0; break;
    }
    drawScoreboard();
    publishScoreState(true);
  }
  processPlayerNames();
  const uint32_t rejected = rejectedCommands.exchange(0);
  if (rejected) Serial.printf("BLE commands rejected (invalid or queue full): %lu\n",
                              static_cast<unsigned long>(rejected));
}

// ================== DRAW FUNCTION ==================
static void drawPlayerRow(const char *name, int score, int baseline, uint16_t color) {
  const int margin = 6;
  const String scoreText = String(score);
  int16_t x, y;
  uint16_t nameWidth, scoreWidth, height;

  dma_display->setFont(&FreeSansBold9pt7b);
  dma_display->getTextBounds(name, 0, 0, &x, &y, &nameWidth, &height);
  dma_display->getTextBounds(scoreText, 0, 0, &x, &y, &scoreWidth, &height);

  int textY = baseline;
  if (nameWidth + scoreWidth + 3 * margin > PANEL_RES_X) {
    // The built-in 6-pixel advance fits eight name characters and a full 32-bit score.
    dma_display->setFont(nullptr);
    dma_display->getTextBounds(scoreText, 0, 0, &x, &y, &scoreWidth, &height);
    textY -= 7;
  }

  dma_display->setTextColor(color);
  dma_display->setCursor(margin, textY);
  dma_display->print(name);
  dma_display->setCursor(PANEL_RES_X - scoreWidth - margin, textY);
  dma_display->print(scoreText);
}

void drawScoreboard() {
  dma_display->clearScreen();
  dma_display->setTextWrap(false);
  dma_display->drawFastHLine(0, 34, PANEL_RES_X, dma_display->color565(40,40,40));
  drawPlayerRow(playerNames.p2, scorePlayerTwo, 26, dma_display->color565(0,255,0));
  drawPlayerRow(playerNames.p1, scorePlayerOne, 54, dma_display->color565(0,0,255));
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

  loadPlayerNames();
  drawScoreboard();
  setupScoreBle();
}


// ================== LOOP ==================
void loop() {

  processScoreBle();

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
      publishScoreState(true);

      wasPressed[i] = false;

      // debounce
      delay(20);
    }
  }
}