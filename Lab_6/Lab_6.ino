// processing communication protocol:
// Live: R,Hz,volts,volts,volts,D
// Fast: F,Hz,volts,volts,volts,D

#define BUTTON 2
#define READ_DURATION 15000

volatile int readValues = 0;

void setup() {
  Serial.begin(115200);
  pinMode(BUTTON, INPUT_PULLUP);
  // digitalWrite(BUTTON, HIGH);
  attachInterrupt(1, buttonISR, FALLING);
}

void loop() {
  int sensorValue;
  float voltage;
  if (readValues) {
    unsigned long timer = millis();
    while ((timer + READ_DURATION) > millis()) {
      Serial.println(getOscilloscopeValue());
    }
    readValues = 0;
  }
}

void buttonISR() {
  readValues = 1;
}

float getOscilloscopeValue() {
  int sensorValue = analogRead(A0);
  float voltage = sensorValue * (5.0 / 1023.0);
  return voltage;
}
