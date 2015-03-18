import processing.serial.*;
import java.util.*;

//Serial
Serial aPort; // Arduino serial port
int noiseRemoval = 0; // skip initial serial readings to eliminiate innacurate values caused by noise

//Voltage Readings
Queue<Integer> voltageValues = new LinkedList<Integer>(); // linked list to sort serial data FIFO

int falloffCount = 150; // number of values to be displayed simultaneously on the screen
int threshold = 150; // oscilloscope trigger threshold set by knob
int thresholdCurrent = 150; // threshold at beginning of draw loop

static final int ARDUINO_SAMPLE_RATE = 11775; // Hz

// Window Dimensions
static final int WINDOW_X = 1000;
static final int WINDOW_Y = 650;

// Oscilloscope Dimensions
static final int OSCILLOSCOPE_X = 50;
static final int OSCILLOSCOPE_Y = 50;
static final int OSCILLOSCOPE_OFFSET = 50;
static final int OSCILLOSCOPE_WIDTH = 700;
static final int OSCILLOSCOPE_HEIGHT = 500;
static final int OSCILLOSCOPE_FLOOR = 549;
static final int[] CURVE_COLOUR = {
  255, 237, 11
}; 
float vMax = 0;
float vMin = 0;
float vP2P = 0;



// Background Image
PImage backgroundImage;
static final String OSCILLOSCOPE_IMAGE = "oscilloscopeFull.png";

// Grids
static final int[] GRID_COLOUR = {
  0, 40, 63
};
PGraphics[] grids = new PGraphics[4];
static final int[] GRID_SIZES = {
  20, 25, 50, 100
};
int currentGrid = 0;

// Knob Objects
knob gridKnob; // used for grid granularity adjustment
knob threshKnob; // used for trigger threshold adjustment
knob falloffKnob; // used to adjust oscilloscope falloff value

static final String KNOB_IMAGE = "knob.png";
static final String KNOB_ALPHA = "knob-alpha.png";

void setup() {
  size(WINDOW_X, WINDOW_Y);
  backgroundImage = loadImage(OSCILLOSCOPE_IMAGE);

  //Serial Port
  println(Serial.list()); // print list of open serial ports
  aPort = new Serial(this, Serial.list()[0], 115200); // initialize serial port
  aPort.buffer(1);

  initGrids(); // Create the grids for rendering but don't draw them yet
  gridKnob = new knob(898, 270, 4); // Creates a knob at X, Y with W switch settings.
  threshKnob = new knob(898, 420, 4); // Creates a knob at X, Y with W switch settings.
  falloffKnob = new knob(898, 570, 4); // Creates a knob at X, Y with W switch settings.
  
  // initialize GUI
  background(backgroundImage);
  drawGridValues(); // dynamic labels
  drawGrid(grids[currentGrid]);
}

void draw() {
  thresholdCurrent = threshold;
  
  if (voltageValues.peek() != null) {
    if (voltageValues.peek() >= thresholdCurrent) {
      if (voltageValues.size() >= falloffCount) {
  
        background(backgroundImage); // We need to redraw the background to clear the screen every time
        drawGrid(grids[currentGrid]);
        drawCurve();
        drawGridValues();      
    }
    } else {
      voltageValues.remove(); 
    }
  }

  drawGridBorder(); // mask oscilloscope data
  
  //drawTextValues(); // dynamic labels // label with image clear to eliminate overlapping current and previous values
  gridKnob.drawKnob();
  threshKnob.drawKnob();
  falloffKnob.drawKnob();
}

void serialEvent(Serial p) {
  int dataIn = byte(aPort.read()) & 0xFF;
  
  if (noiseRemoval > 100) {
    voltageValues.add(dataIn);
  } else {
    noiseRemoval++;
  }
  
  println(dataIn);
}

void drawGridValues() {
  textSize(30);
  
  // Time Scale of grid - calculated in microseconds
  int totalSegments = OSCILLOSCOPE_WIDTH / GRID_SIZES[currentGrid];
  float scale = ARDUINO_SAMPLE_RATE / totalSegments;
  text(str(scale) + " µs", 840, 220);
}

void drawGridBorder() {
  pushMatrix();
  noFill();
  strokeWeight(3);
  strokeCap(ROUND);
  //hint(ENABLE_STROKE_PURE); // This increases the draw quality of a stroke at the expense of performance - enables anti - aliasing
  stroke(GRID_COLOUR[0], GRID_COLOUR[1], GRID_COLOUR[2]);
  rect(OSCILLOSCOPE_OFFSET - 1, OSCILLOSCOPE_OFFSET -1, OSCILLOSCOPE_WIDTH + 1, OSCILLOSCOPE_HEIGHT + 1);
  popMatrix();
}

/* draws oscilloscope curve given starting index */
void drawCurve() { // starting index
  float time;
  float volts;
  
  pushMatrix();
  noFill();
  curveTightness(1.0); // modifies quality of vertex
  translate(OSCILLOSCOPE_OFFSET - 3, OSCILLOSCOPE_OFFSET);
  strokeWeight(2);
  stroke(CURVE_COLOUR[0], CURVE_COLOUR[1], CURVE_COLOUR[2]);
  
  beginShape();
  for (int x = 0; x < falloffCount; x++) {
    // maps values to correct screen ratio
    volts = float(voltageValues.remove());
    getVoltsDisplay(volts);
    volts = map(volts, 0, 255, 30, OSCILLOSCOPE_HEIGHT - 30);
    
    time = map(x, 0, falloffCount, 0, OSCILLOSCOPE_WIDTH + 6);
    curveVertex(time, volts);
  }
  endShape();
  popMatrix();
  
 drawVoltText();
  
  voltageValues.clear();
  
  //reset voltage calculations
  vMax = 0;
  vMin = 0;
}

void drawVoltText() {
 vP2P = vMax - vMin;

 textSize(30);

 text(vMax, 892, 45);
 text(vP2P, 892, 100);
 text(vMin, 892, 165); 
}


void getVoltsDisplay(float volts) {
  float v = map(volts, 0, 255, 0, 5);
  if (v > vMax) vMax = v;
  if (v < vMin) vMin = v;
}

// create a grid
void initGrids() {
  for (int i = 0; i < GRID_SIZES.length; i++) {
    grids[i] = createGraphics(OSCILLOSCOPE_WIDTH, OSCILLOSCOPE_HEIGHT);
    grids[i].beginDraw();
    fill(GRID_COLOUR[0], GRID_COLOUR[1], GRID_COLOUR[2]);
    for (int x = 0; x < OSCILLOSCOPE_WIDTH; x += GRID_SIZES[i]) { // draw horizontal lines
      grids[i].line(x, 0, x, OSCILLOSCOPE_HEIGHT);
    }
    for (int y = 0; y < OSCILLOSCOPE_HEIGHT; y += GRID_SIZES[i]) { // draw vertical lines
      grids[i].line(0, y, OSCILLOSCOPE_WIDTH, y);
    }
    grids[i].endDraw();
  }
}


// Draws a new grid
void drawGrid(PGraphics grid) {
  imageMode(CORNER); // interprets following image placement parameters as location of corner (4th and 5th parameters would be opposite corner
  image(grid, OSCILLOSCOPE_OFFSET, OSCILLOSCOPE_OFFSET);
}

// performs set actions as soon as the mouse is pressed down. Does not wait for the mouse button to release back up.
void mousePressed() {
  if (gridKnob.isMouseOver()) { // Test to see if the mouse was pressed on this knob.
    gridKnob.rotateKnob(); // Rotate the knob
    currentGrid = gridKnob.position; // Change the grid to the new position
    //drawTextValues(); // dynamic labels
  }

  if (threshKnob.isMouseOver()) { 
    threshKnob.rotateKnob();
    switch(threshKnob.position) {
    case 0:
      threshold = 100;
      break;
    case 1:
      threshold = 150;
      break;
    case 2:
      threshold = 200;
      break;
    case 3:
      threshold = 255;
      break;
    }
  }

  if (falloffKnob.isMouseOver()) { 
    falloffKnob.rotateKnob();
    switch(falloffKnob.position) {
    case 0:
      falloffCount = 50;
      break;
    case 1:
      falloffCount = 100;
      break;
    case 2:
      falloffCount = 150;
      break;
    case 3:
      falloffCount = 197;
      break;
    }
  } 

}

// Knob Class
class knob {
  PImage knobImage; // Image of the knob
  PImage knobAlpha; // Alpha channel of the knob
  int x, y; // knob location on the screen
  int size; // The width and height of the knob
  int rotation = 0; // where in 2D space the knob is rotated to. Zero is north and is the default position of the knob.
  int knotches; // how many settings this knob has
  int lastPosition = 0; // Tracking for the last position the knob was on
  int position = 0; // Tracking for the current position the knob is on. Useful for syncing the knob to it's controllable object.

  int[] initial = {
    0, 0, -45, -45, -90, -90
  }; // based on how many settings the knob has, this is its starting point. The absolute value is its end point. A knob points north by default.

  // Knob Constructor
  knob(int xPosition, int yPosition, int settings) {
    knobImage = loadImage(KNOB_IMAGE); // load the image of the knob
    knobAlpha = loadImage(KNOB_ALPHA); // load the knob's alpha channel
    knobImage.mask(knobAlpha); // subtract the alpha channel from the image of the knob
    rotation = initial[settings]; // Ensures that when the knob is drawn for the first time it's at its default position
    knotches = settings;
    x = xPosition; // x and y coordinates
    y = yPosition; // are drawn from the centre
    size = knobImage.height; // Knobs will always have the same height/width so set to a universal name.
  }

  void drawKnob() {
    pushMatrix();
    imageMode(CENTER); // Draws from the centre
    translate(x, y); // Moves our 0, 0 point to x and y so all references happen from a centralized point.
    rotate(radians(rotation)); // set knob orientation
    image(knobImage, 0, 0); // draw the knob in the window
    popMatrix();
  }

  void rotateKnob() {
    switch (knotches) {

    case 2: // States for a 2 position knob
      if (rotation == -45) {
        rotation += 90;
        position = 1;
      } else {
        rotation -= 90;
        position = 0;
      }
      break;

    case 3: // States for a 3 position knob
      if (rotation == -45) {
        rotation += 45;
        lastPosition = 0;
        position = 1;
      } else if (rotation == 0 && lastPosition == 0) {
        rotation += 45;
        lastPosition = 1;
        position = 2;
      } else if (rotation == 45) {
        rotation -= 45;
        lastPosition = 2;
        position = 1;
      } else if (rotation == 0 && lastPosition == 2) {
        rotation -= 45;
        lastPosition = 1;
        position = 0;
      }        
      break;

    case 4: // States for a 4 position knob
      if (rotation == -90) {
        rotation += 60;
        lastPosition = 0;
        position = 1;
      } else if (rotation == -30 && lastPosition == 0) {
        rotation += 60;
        lastPosition = 1;
        position = 2;
      } else if (rotation == 30 && lastPosition == 1) {
        rotation += 60;
        lastPosition = 2;
        position = 3;
      } else if (rotation == 90) {
        rotation -= 60;
        lastPosition = 3;
        position = 2;
      } else if (rotation == 30 && lastPosition == 3) {
        rotation -= 60;
        lastPosition = 2;
        position = 1;
      } else if (rotation == -30 && lastPosition == 2) {
        rotation -= 60;
        lastPosition = 1;
        position = 0;
      }
      break;

    case 5: // States for a 5 position knob (if we ever need it...)

      break;
    }
  }

  boolean isMouseOver() {
    return (mouseX >= (x - size / 2)) && (mouseX <= (x + size / 2)) && (mouseY >= (y - size / 2)) && (mouseY <= (y + size / 2));
  }
}

