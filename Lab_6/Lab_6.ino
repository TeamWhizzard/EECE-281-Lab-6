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
#define LEDPIN 7
#define READ_DURATION 15000000 // microseconds to sample for

volatile bool readingValues = false;
volatile uint8_t voltage;
volatile unsigned long timeButtonLastPressed;
volatile unsigned long timeStartMeasuring;

// debugging junk
volatile unsigned long numValuesRead;
volatile unsigned long lastRead;

void setup() {
  Serial.begin(115200);
  pinMode(BUTTON, INPUT_PULLUP);
  attachInterrupt(1, buttonISR, CHANGE); // Arduino interrupt 1 connects to Digital Pin 2
  pinMode(LEDPIN, OUTPUT);
  digitalWrite(LEDPIN, LOW);
  // based on: http://garretlab.web.fc2.com/en/arduino/inside/arduino/wiring_analog.c/analogRead.html
  // datasheet: http://www.atmel.com/images/Atmel-8271-8-bit-AVR-Microcontroller-ATmega48A-48PA-88A-88PA-168A-168PA-328-328P_datasheet_Complete.pdf
  // around page 234 is useful
  // also nice: http://openenergymonitor.blogspot.ca/2012/08/low-level-adc-control-admux.html

  // set the analog reference (high two bits of ADMUX) and select the
  // channel (low 4 bits).  this also sets ADLAR (left-adjust result)
  // to 0 (the default).
  // page 248 in datasheet describes ADMUX
  // chooses:
  // REFS = 01 (internal voltage reference)
  // ADLAR = 1 (sets ADC value left-aligned, so we can just read ADCH (high bits)
  // sets mux to read analog pin 0
  ADMUX = 0b01100000;

  // decided on 1Mhz adc clock based on http://www.openmusiclabs.com/learning/digital/atmega-adc/
  // reference: page 249 in datasheet
  // ADCSRA bits from high to low
  // --------------------------------------------------------------
  // ADEN  = 1   ADC enabled
  // ADSC  = 0   ADC doesn't need to start conversion yet
  // ADATE = 1   ADC autotrigger enabled
  // ADIF  = 0   ADC interrupt flag (off?)
  // ADIE  = 1   ADC interrupt enabled
  // ADPS2 = 1   ADC prescaler bit (divide 16 MHz by 16)
  // ADPS1 = 0   ADC prescaler bit (page 250 in datasheet)
  // ADPS0 = 0   ADC prescaler bit
  ADCSRA = 0b10101100;

  //ADCSRB = 0b00000000 | ADCSRB;

  // turn off digital input buffers for analog pins.
  // Arduino core might already do this, but let's do it again anyway.
  DIDR0 = 0b00111111;
}

void loop() {
  // check if we're supposed to be reading values
  if (readingValues) {
    // check if the button timer has elapsed
    // if this is broken, let's have a longer look at
    // http://stackoverflow.com/questions/61443/rollover-safe-timer-tick-comparisons
    // http://playground.arduino.cc/Code/TimingRollover
    if (micros() - timeButtonLastPressed > READ_DURATION) {
      readingValues = false;
      digitalWrite(LEDPIN, LOW);
      
      // timing/debug output barf
      //float secondsElapsed = float(micros() - timeStartMeasuring) / 1000000.0;
      //Serial.println(" ");
      //Serial.println(String(secondsElapsed) + " seconds elapsed"); // output total time timer was on
      //Serial.println(String(numValuesRead) + " values read");
      //Serial.println(String(float(numValuesRead) / (float(secondsElapsed))) + " samples per second");
      //numValuesRead = 0;
    } else {
      Serial.write( char(voltage) );
      numValuesRead++; // could remove this, but kept it in for timing purposes
      // Serial.flush()
      // If we want to prevent blocking on the Serial.write() above, we can Serial.flush(),
      // But it knocks a bunch off our throughput, so I'm going to stop.
    }
  }
}

// ADC interrupt service routine
ISR(ADC_vect) {
  voltage = ADCH;
}

void buttonISR() {
  if (readingValues == true) {
    timeButtonLastPressed = micros();
  } else {
    timeStartMeasuring = micros();
    readingValues = true;
    timeButtonLastPressed = micros();
    digitalWrite(7, HIGH);
  }
}
