// processing communication protocol:
// Live: R,Hz,volts,volts,volts,D
// Fast: F,Hz,volts,volts,volts,D

void setup() {
  Serial.begin(115200);
  
  attachInterrupt(0, liveISR, HIGH);  //init hardware interrupt 0 for digital pin 2
  attachInterrupt(1, fastISR, HIGH);  //init hardware interrupt 1 for digital pin 3
}

void loop() {}

void liveISR() {
  oscilloscopeLive();
}

void fastISR() {
 // TODO 
}

void oscilloscopeLive() {
  Serial.print("R"); // intial message
  int timer = millis();
  byte inputV;
  float voltage;
  
  while ((timer + 1500) < millis()) { // display live voltage for fifteen seconds
    Serial.print(",");
    Serial.print(voltage);
  }
   
}
