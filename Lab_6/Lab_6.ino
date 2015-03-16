// processing communication protocol:
// Live: R,Hz,volts,volts,volts,D
// Fast: F,Hz,volts,volts,volts,D

#define BUTTON 2
#define READ_DURATION 2000000 // microseconds to sample for

volatile int readValues = 0;
volatile float voltage;
volatile unsigned long lastRead;
volatile unsigned long timer;
    
void setup() {
  Serial.begin(115200);
  pinMode(BUTTON, INPUT_PULLUP);
  attachInterrupt(1, buttonISR, FALLING); // Arduino interrupt 1 connects to Digital Pin 2
  Serial.println("WhizzardScope standing by....");
}

void loop() {
  if (readValues) {
    timer = micros();
    while ((timer + READ_DURATION) > micros()) {
      getOscilloscopeValue();
      Serial.println( String(voltage) + ", " + String(micros()-lastRead));
      lastRead = micros();
    }
    readValues = 0;
  }
}

void buttonISR() {
  readValues = 1;
}

float getOscilloscopeValue() {
  int sensorValue = analogRead(A0);
  voltage = sensorValue * (5.0 / 1023.0);
  return voltage;
}
