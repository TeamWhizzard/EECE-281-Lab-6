void setup() {
  Serial.begin(9600);
  for (int i = 0; i <= 20; i++) {
    char serialByte = random(0, 255);
    Serial.write(serialByte);
  }
}

void loop() {

}

