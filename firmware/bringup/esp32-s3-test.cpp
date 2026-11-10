void setup() {
  delay(1000);                 // give USB time to enumerate
  Serial.begin(115200);
  while (!Serial) { delay(10); } // wait for USB CDC

  Serial.println("ESP32-S3 booted successfully!");
}

void loop() {
  static int counter = 0;
  Serial.print("Loop count: ");
  Serial.println(counter++);
  delay(1000);
}
