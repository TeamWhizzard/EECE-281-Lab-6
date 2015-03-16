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

knob knobbytest;

void setup() {
  size(WINDOW_X, WINDOW_Y);
  backgroundImage = loadImage("oscilloscope.png");
  background(backgroundImage);

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

  noLoop();
}

void draw() {
  background(backgroundImage); // We need to redraw the background to clear the screen.
  drawNextSizeGrid();
}

void loop() {
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

