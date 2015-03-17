import processing.serial.*;
import java.util.*;

//Serial
Serial aPort; // Arduino serial port

//Voltage Readings
Queue<Integer> voltageValues = new LinkedList<Integer>();
static final int numDispValues = 5; // number of values that can be displayed simultaneously
static final int threshold = 150;

// Window Dimensions
static final int WINDOW_X = 1000;
static final int WINDOW_Y = 650;

// Oscilloscope Dimensions
static final int OSCILLOSCOPE_X = 50;
static final int OSCILLOSCOPE_Y = 50;
static final int OSCILLOSCOPE_OFFSET = 50;
static final int OSCILLOSCOPE_WIDTH = 700;
static final int OSCILLOSCOPE_HEIGHT = 500;
static final int[] GRID_SIZES = {
  20, 25, 50, 100
};
static final int DEFAULT_GRID = 1;
int currentGridIndex = 1;

// Graphics Objects
PImage backgroundImage;
PGraphics grid20;
PGraphics grid25;
PGraphics grid50;
PGraphics grid100;

// Knob Objects
knob knobbytest;

void setup() {
  size(WINDOW_X, WINDOW_Y);
  backgroundImage = loadImage("oscilloscope.png");
  background(backgroundImage);

  //Serial Port
  println(Serial.list()); // print list of open serial ports
  aPort = new Serial(this, Serial.list()[1], 115200); // initialize serial port
  aPort.buffer(1);

  // Grids, TODO: Move to a function with a loop to create these
  grid20  = createGraphics(OSCILLOSCOPE_WIDTH, OSCILLOSCOPE_HEIGHT);
  makeGrid(grid20, 20);
  grid25  = createGraphics(OSCILLOSCOPE_WIDTH, OSCILLOSCOPE_HEIGHT);
  makeGrid(grid25, 25);
  grid50  = createGraphics(OSCILLOSCOPE_WIDTH, OSCILLOSCOPE_HEIGHT);
  makeGrid(grid50, 50);
  grid100 = createGraphics(OSCILLOSCOPE_WIDTH, OSCILLOSCOPE_HEIGHT);
  makeGrid(grid100, 100);

  knobbytest = new knob("testknob.png", 900, 100);
  knobbytest.drawKnob();

  //noLoop();
}

void draw() {
  if (voltageValues.peek() != null) {
    if (voltageValues.peek() >= threshold) {
      if (voltageValues.size() >= numDispValues) {
        background(backgroundImage); // We need to redraw the background to clear the screen.
        drawCurve();
      }
    } else if (voltageValues.peek() < threshold) {
      voltageValues.remove();
    }
  }

  //drawNextSizeGrid();
}

void serialEvent(Serial p) {
  int dataIn = byte(aPort.read()) & 0xFF;
  voltageValues.add(dataIn);
  //println(dataIn);
}


/* draws oscilloscope curve given starting index */
void drawCurve() { // starting index
  int xCoord = 0;
  float volts;
  //  clear(); // clear screen to redraw curve

  smooth();
  fill(255);

  beginShape();
  for (int i = 0; i < numDispValues; i++) {
    volts = float(voltageValues.remove());
    volts = map(volts, 0, 255, 0, 5);
    volts = map(volts, 0, 5, 0, OSCILLOSCOPE_HEIGHT);
    //println(voltageValues.size());
    curveVertex(xCoord, volts); 
    xCoord+= OSCILLOSCOPE_WIDTH / numDispValues;
  }
  endShape();
}

// Adjust Grid Sizing. Grid index must be between the sizes defined in GRID_SIZES.
void makeGrid(PGraphics grid, int gridSize) {
  grid.beginDraw();
  fill(255);
  for (int i = 0; i < OSCILLOSCOPE_WIDTH; i += gridSize) {
    grid.line(i, 0, i, OSCILLOSCOPE_HEIGHT);
  }
  for (int i = 0; i < OSCILLOSCOPE_HEIGHT; i += gridSize) {
    grid.line(0, i, OSCILLOSCOPE_WIDTH, i);
  }
  grid.endDraw();
}

void mouseClicked() {
  redraw();
}

void drawNextSizeGrid() {
  imageMode(CORNER);
  switch (currentGridIndex) {
  case 0:
    grid100.clear();
    image(grid20, OSCILLOSCOPE_OFFSET, OSCILLOSCOPE_OFFSET);
    currentGridIndex++;
    break;
  case 1:
    grid20.clear();
    image(grid25, OSCILLOSCOPE_OFFSET, OSCILLOSCOPE_OFFSET);
    currentGridIndex++;
    break;
  case 2:
    grid25.clear();
    image(grid50, OSCILLOSCOPE_OFFSET, OSCILLOSCOPE_OFFSET);
    currentGridIndex++;
    break;
  case 3:
    grid50.clear();
    image(grid100, OSCILLOSCOPE_OFFSET, OSCILLOSCOPE_OFFSET);
    currentGridIndex = 0;
    break;
  }
}

// Knob Class
class knob {
  PImage myKnob;
  int x, y;

  // Knob Constructor
  knob(String knobImage, int x, int y) {
    this.myKnob = loadImage(knobImage);
    this.x = x;
    this.y = y;
  }

  void drawKnob() {
    imageMode(CENTER);
    image(myKnob, x, y);
  }

  void rotateKnob() {
    clear();
    imageMode(CENTER);
    translate(width / 2, height / 2);
    rotate(QUARTER_PI);
  }

  boolean isMouseOver() {
    boolean knobHover = (mouseX >= x && mouseX <= x + myKnob.width && mouseY >= y && mouseY <= y + myKnob.height);
    return knobHover;
  }
}

