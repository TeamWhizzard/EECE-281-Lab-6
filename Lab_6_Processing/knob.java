import processing.core.*;

// Knob Class
class knob {
  PApplet parent;
  PImage myKnob;
  int x, y;
  int state;

  // Knob Constructor
  knob(PApplet parent, String knobImage, int x, int y, int state) {
    this.parent = parent;
    this.myKnob = parent.loadImage(knobImage);
    this.x = x;
    this.y = y;
    this.state = state;
  }

  void drawKnob() {
    parent.imageMode(parent.CENTER);
    parent.image(myKnob, x, y);
  }

  void rotateKnob() {
    parent.clear();
    //imageMode(CENTER);
    parent.translate(myKnob.width / 2, myKnob.height / 2);
    parent.rotate(parent.QUARTER_PI);
  }

  boolean isMouseOver() {
    boolean knobHover = (parent.mouseX >= x && parent.mouseX <= x + myKnob.width && parent.mouseY >= y && parent.mouseY <= y + myKnob.height);
    return knobHover;
  }
}
