// GPIO assignments
const int BTN_A = 12;
const int BTN_B = 13;
const int BTN_C = 14;

const unsigned long LONG_PRESS_MS = 600;

// Track timing
unsigned long pressStart[3] = {0, 0, 0};
bool wasPressed[3] = {false, false, false};

int buttons[3] = {BTN_A, BTN_B, BTN_C};

void setup() {
  Serial.begin(115200);
  delay(500);

  for (int i = 0; i < 3; i++) {
    pinMode(buttons[i], INPUT_PULLUP);
  }

  Serial.println("Button test ready");
}

void loop() {
  for (int i = 0; i < 3; i++) {
    bool pressed = digitalRead(buttons[i]) == LOW;

    if (pressed && !wasPressed[i]) {
      pressStart[i] = millis();
      wasPressed[i] = true;
    }

    if (!pressed && wasPressed[i]) {
      unsigned long duration = millis() - pressStart[i];

      Serial.print("Button ");
      Serial.print(i + 1);

      if (duration >= LONG_PRESS_MS) {
        Serial.println(" LONG press");
      } else {
        Serial.println(" SHORT press");
      }

      wasPressed[i] = false;
    }
  }
}
