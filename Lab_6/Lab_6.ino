/* EECE 281
 * Lab 6 - The WhizzardScope
 * 
 *      Team Whizzard is...
 *                           .
 *               /^\     .
 *          /\   "V"
 *         /__\   I      L  .           John Deppe
 *        //..\\  I        a               Theresa Mammarella
 *        \].`[/  I       b                   Steven Olsen
 *       /l\/j\  (]    .   6
 *       /. ~~ ,\/I          .
 *       \\L__j^\/I       o
 *        \/--v}  I     o   .
 *        |    |  I   _________
 *        |    |  I c(`       ')o
 *        |    l  I   \.     ,/
 *       _/j  L l\_!  _//^---^\\_
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */

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
volatile unsigned long numValuesRead = 0;
volatile unsigned long numValuesMeasured = 0;
volatile unsigned long lastRead;

void setup() {
  Serial.begin(115200);
  pinMode(BUTTON, INPUT_PULLUP);
  attachInterrupt(0, buttonISR, CHANGE); // Interrupt 0 connects to Pin 2
  pinMode(LEDPIN, OUTPUT);
  digitalWrite(LEDPIN, HIGH);
  
  // References for the following ATMega328 register manipulations
  // based on: http://garretlab.web.fc2.com/en/arduino/inside/arduino/wiring_analog.c/analogRead.html
  // datasheet: http://www.atmel.com/images/Atmel-8271-8-bit-AVR-Microcontroller-ATmega48A-48PA-88A-88PA-168A-168PA-328-328P_datasheet_Complete.pdf
  // around page 234 is useful
  // also nice: http://openenergymonitor.blogspot.ca/2012/08/low-level-adc-control-admux.html
  
  // ADMUX bits from high to low
  // --------------------------------------------------------------
  // REFS1 = 0   select Arduino-std voltage reference
  // REFS0 = 1   select Arduino-std voltage reference
  // ADLAR = 1   left-aligned ADC reference (lets us pull just high values, ADCH)
  // resvd = 0   write 0 for compatibility
  // MUX3  = 0   select ADC0
  // MUX2  = 0   select ADC0
  // MUX1  = 0   select ADC0
  // MUX0  = 0   select ADC0
  ADMUX = 0b01100000;

  // decided on 1Mhz adc clock based on http://www.openmusiclabs.com/learning/digital/atmega-adc/
  // reference: page 249 in datasheet
  // ADCSRA bits from high to low
  // --------------------------------------------------------------
  // ADEN  = 1   ADC enabled
  // ADSC  = 1   ADC start measuring
  // ADATE = 1   ADC autotrigger enabled
  // ADIF  = 0   ADC interrupt flag (off?)
  // ADIE  = 1   ADC interrupt enabled
  // ADPS2 = 1   ADC prescaler bit (divide 16 MHz by 16)
  // ADPS1 = 0   ADC prescaler bit (page 250 in datasheet)
  // ADPS0 = 0   ADC prescaler bit
  ADCSRA = 0b11101100;

  // ADCSRB bits from high to low
  // --------------------------------------------------------------
  // resvd = 0   write 0 for compatibility
  // ACME  = 0   not using Analog Comparator
  // resvd = 0   write 0 for compatibility
  // resvd = 0   write 0 for compatibility
  // resvd = 0   write 0 for compatibility
  // ADTS2 = 0   free running mode
  // ADTS1 = 0   free running mode
  // ADTS0 = 0   free running mode
  ADCSRB = 0b00000000;

  // turn off digital input buffers for analog pins.
  // suggested by: http://www.openmusiclabs.com/learning/digital/atmega-adc/
  // Arduino core might already do this, but let's do it again anyway.
  DIDR0 = 0b00111111;
  
  // set global interrupt bit on
  //sei();
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
      digitalWrite(LEDPIN, HIGH);
      
      // timing/debug output barf
      //float secondsElapsed = float(micros() - timeStartMeasuring) / 1000000.0;
      //Serial.println(" ");
      //Serial.println(String(numValuesMeasured) + " values measured");
      //Serial.println(String(secondsElapsed) + " seconds elapsed"); // output total time timer was on
      //Serial.println(String(numValuesRead) + " values read");
      //Serial.println(String(float(numValuesRead) / (float(secondsElapsed))) + " samples per second");
      //numValuesRead = 0;
      //numValuesMeasured = 0;
    } else {
      Serial.write( char(voltage) );
      numValuesRead++; // could remove this, but kept it in for timing purposes
      // Serial.flush();
      // If we want to prevent blocking on the Serial.write() above, we can Serial.flush(),
      // But it knocks a bunch off our throughput, so I'm going to stop.
    }
  }
}

// ADC interrupt service routine
ISR(ADC_vect) {
  voltage = ADCH;
  //numValuesMeasured++;
}

void buttonISR() {
  if (readingValues == true) {
    timeButtonLastPressed = micros();
  } else {
    timeStartMeasuring = micros();
    readingValues = true;
    timeButtonLastPressed = micros();
    digitalWrite(7, LOW);
  }
}
