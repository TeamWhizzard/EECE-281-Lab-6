// processing communication protocol:
// Live: R,Hz,volts,volts,volts,D
// Fast: F,Hz,volts,volts,volts,D


// from: http://playground.arduino.cc/Main/AVR
#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif


#define BUTTON 2
#define READ_DURATION 15000000 // microseconds to sample for

volatile int readValues = 0;
volatile uint8_t voltage;
volatile unsigned long numValuesRead;
volatile unsigned long lastRead;
volatile unsigned long timer;

void setup() {
  Serial.begin(115200);
  pinMode(BUTTON, INPUT_PULLUP);
  //attachInterrupt(1, buttonISR, FALLING); // Arduino interrupt 1 connects to Digital Pin 2
  adcSetup();
}
void loop() {
  //if (readValues) {
    timer = micros();
    numValuesRead = 0;
    while( (timer + READ_DURATION) > micros() ) {
      voltage = adcRead();
      Serial.write( char(voltage) );
      numValuesRead++;
    }
    readValues = 0;
    Serial.println(" ");
    Serial.println(String(micros() - timer)); // output total time timer was on
    Serial.println(String(numValuesRead));
  //}
}

void buttonISR() {
  static unsigned long lastPress;
  if (lastPress + READ_DURATION < micros()) {
    readValues = 1;
    lastPress = micros();
  }
}

// based on: http://garretlab.web.fc2.com/en/arduino/inside/arduino/wiring_analog.c/analogRead.html
// datasheet: http://www.atmel.com/images/Atmel-8271-8-bit-AVR-Microcontroller-ATmega48A-48PA-88A-88PA-168A-168PA-328-328P_datasheet_Complete.pdf
// around page 234 is useful
// also nice: http://openenergymonitor.blogspot.ca/2012/08/low-level-adc-control-admux.html
void adcSetup() {
  // set the analog reference (high two bits of ADMUX) and select the
  // channel (low 4 bits).  this also sets ADLAR (left-adjust result)
  // to 0 (the default).
  // page 248 in datasheet describes ADMUX
  // chooses:
  // REFS = 01 (internal voltage reference)
  // ADLAR = 1 (sets ADC value left-aligned, so we can just read ADCH (high bits)
  // sets mux to read analog pin 0
  ADMUX = 0b01100000;
  //
  // with: http://www.openmusiclabs.com/learning/digital/atmega-adc/
  // decided on 1Mhz adc clock
  // reference: page 249 in datasheet
  ADCSRA = 0b10000100;
  
  //ADCSRB = 0b00000000 | ADCSRB;
  
  // suggested by music doods
  DIDR1 = 0b00000000;
}

uint8_t adcRead() {
  sbi(ADCSRA, ADSC);

  // ADSC is cleared when the conversion finishes
  while (bit_is_set(ADCSRA, ADSC));

  // we have to read ADCL first; doing so locks both ADCL
  // and ADCH until ADCH is read.  reading ADCL second would
  // cause the results of each conversion to be discarded,
  // as ADCL and ADCH would be locked when it completed.
  //low  = ADCL;

  return ADCH;

}
