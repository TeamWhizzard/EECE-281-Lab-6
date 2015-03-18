import processing.serial.*;
import java.util.*;

//Serial
Serial aPort; // Arduino serial port

//Voltage Readings
Queue<Integer> voltageValues = new LinkedList<Integer>();
int falloffCount = 10; // number of values that can be displayed simultaneously
int threshold = 150;
//static final int BUFFER_FALLOFF = 11768;
boolean oscilloscopeReady = false;

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
//static final int[4] SEGMENTS_PER_DIVISION = {2, 100, 1000, 10000, 100000, 10000000}; // In Microseconds 

// Background Image
PImage backgroundImage;
static final String OSCILLOSCOPE_IMAGE = "oscilloscope.png";

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
knob falloffKnob; // used to adjust number of samples displayed
static final String KNOB_IMAGE = "knob.png";
static final String KNOB_ALPHA = "knob-alpha.png";

void setup() {
  size(WINDOW_X, WINDOW_Y);
  backgroundImage = loadImage(OSCILLOSCOPE_IMAGE);

  //Serial Port
  println(Serial.list()); // print list of open serial ports
  aPort = new Serial(this, Serial.list()[1], 115200); // initialize serial port
  aPort.buffer(1);

  initGrids(); // Create the grids for rendering but don't draw them yet
  gridKnob = new knob(898, 200, 4); // Creates a knob at X, Y with W switch settings.
  threshKnob = new knob(898, 350, 4); // Creates a knob at X, Y with W switch settings.
  falloffKnob = new knob(898, 500, 4); // Creates a knob at X, Y with W switch settings.
}

void draw() {
  if (voltageValues.peek() != null) {
    if (voltageValues.peek() >= threshold) {
      if (voltageValues.size() >= falloffCount) {
        background(backgroundImage); // We need to redraw the background to clear the screen every time
        drawCurve();
      }
    }
  }
  drawGrid(grids[currentGrid]);
  drawGridBorder();
  gridKnob.drawKnob();
  threshKnob.drawKnob();
  falloffKnob.drawKnob();
}

void serialEvent(Serial p) {
  int dataIn = byte(aPort.read()) & 0xFF;
  voltageValues.add(dataIn);
}

void checkThreshold() {
}

void drawGridBorder() {
  pushMatrix();
  noFill();
  strokeWeight(3);
  strokeCap(ROUND);
  hint(ENABLE_STROKE_PURE); // This increases the draw quality of a stroke at the expense of performance
  stroke(GRID_COLOUR[0], GRID_COLOUR[1], GRID_COLOUR[2]);
  rect(OSCILLOSCOPE_OFFSET - 1, OSCILLOSCOPE_OFFSET -1, OSCILLOSCOPE_WIDTH + 1, OSCILLOSCOPE_HEIGHT + 1);
  popMatrix();
}

/* draws oscilloscope curve given starting index */
void drawCurve() { // starting index
  int time;
  float volts;
  pushMatrix();
  noFill();
  translate(OSCILLOSCOPE_OFFSET - 3, OSCILLOSCOPE_OFFSET);
  strokeWeight(2);
  stroke(CURVE_COLOUR[0], CURVE_COLOUR[1], CURVE_COLOUR[2]);
  beginShape();
  for (int x = 0; x < falloffCount; x++) {
    // maps values to correct screen ratio
    volts = float(voltageValues.remove());
    println(voltageValues.size());
    volts = map(volts, 0, 255, 0, OSCILLOSCOPE_HEIGHT);
    time = (int) map(x, 0, falloffCount, 0, OSCILLOSCOPE_WIDTH + 6);
    curveVertex(time, volts);
  }
  endShape();
  popMatrix();

  voltageValues.clear();
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
  imageMode(CORNER);
  image(grid, OSCILLOSCOPE_OFFSET, OSCILLOSCOPE_OFFSET);
}

// performs set actions as soon as the mouse is pressed down. Does not wait for the mouse button to release back up.
void mousePressed() {
  if (gridKnob.isMouseOver()) { // Test to see if the mouse was pressed on this knob.
    gridKnob.rotateKnob(); // Rotate the knob
    currentGrid = gridKnob.position; // Change the grid to the new position
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
      falloffCount = OSCILLOSCOPE_WIDTH / 6;
      break;
    case 1:
      falloffCount = OSCILLOSCOPE_WIDTH / 4;
      break;
    case 2:
      falloffCount = OSCILLOSCOPE_WIDTH / 3;
      break;
    case 3: 
      falloffCount = OSCILLOSCOPE_WIDTH / 2;
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

