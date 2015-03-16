import processing.serial.*;

Serial aPort;

int maxVal = 20;
float[] voltVal = new float[maxVal];

int valIndex = 0; // keeps current last index of array
String mode = ""; // r or f
boolean display = false; // false if currently not displaying live, true if displaying

float dispThresh = 3; // display threshold set by user - TODO knob
int dispIndex = 0; // index of last displayed value
int numDispValues = 5; // number of values that can be displayed simultaneously

void setup()
{   
  size(200, 200);

  // intialize serial input
  println(Serial.list()); // print list of open serial ports
  aPort = new Serial(this, Serial.list()[0], 9600); // initialize serial port
  aPort.bufferUntil(',');
}

void draw() {
  if (mode.equals("R") && display) { // display live
    int i;
    for(i = dispIndex; i <= valIndex; i++) {
      if (voltVal[i] >= dispThresh) { // check if threshold has been triggered
        dispIndex = i;  // set first index to display as value that triggered threshold
        
        // if not enough spaces to redraw, ends display
        if ((maxVal - dispIndex) < numDispValues) {
          display = false;
          break;
        }
        
        while((valIndex - dispIndex) < numDispValues) { println(valIndex - dispIndex); }
        
        drawCurve(); // redraw
        break;
      }
    }

  } else if (mode.equals("F") && display) { // fast display
    // TODO
  }
}

/* oscilloscope control commands */
void serialEvent(Serial p) {
  String aIn = aPort.readStringUntil(',');
  aIn = aIn.replace(",", ""); // remove comma delimiter
  
  if (aIn.equals("R") || aIn.equals("F")) { // set mode
    mode = aIn;
    display = true;
    
  } else if (aIn.equals("D")) { // set start and end 
    display = false;
    
  } else { // add value to buffer
    voltVal[valIndex] = float(aIn);
    valIndex++;
  }
}


/* draws oscilloscope curve given starting index */
void drawCurve() { // starting index
  int i;
  int xCoord = 10; // initialize to oscilloscope graphics margin

  clear(); // clear screen to redraw curve
  background(255);

  smooth();
  noFill();
  stroke(0);

  beginShape();

  for (i = dispIndex; i < (dispIndex + numDispValues); i++) {
    curveVertex(xCoord, voltVal[i]); // voltVal*scale + xAxis 
    xCoord+=10;
  }

  endShape();
  dispIndex += numDispValues;
}

