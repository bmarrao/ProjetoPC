float posx = 450;
float posy = 450;
float posxE = 100;
float posyE = 100;
float angE = 90;
float ang = 0;
float vel = 0;
boolean keys1;
boolean keys2;
boolean keys0;
float[] crystals = new float[16];
float cNum = 0;

void setup() {
  size(900, 900);
  noStroke();
  keys0 = false;
  keys1 = false;
  keys2 = false;
}

void keysAux(){
  if(keys0 && keys2){
    vel += 0.3;
    ang += PI/32;
  }
  else if(keys0 && keys1){
    vel += 0.3;
    ang -= PI/32;
  }
  else if ( keys0) {  
    vel += 0.3;
  }
  else if ( keys1) {
    ang -= PI/32;
  }
  else if ( keys2) {
    ang += PI/32;
  }
  
  
}

void drawCrystals(){
  crystals[0] = 300;
  crystals[1] = 300;
  cNum = 1;
  for (int i = 0; i< cNum;i++){
    quad(crystals[2*i]-25,crystals[2*i + 1]-25 ,crystals[2*i]+25,crystals[2*i + 1]-25,crystals[2*i]+25,crystals[2*i + 1]+25  ,crystals[2*i]-25,crystals[2*i + 1]+25);
  }
}

void drawEnemy(){
  pushMatrix();
  translate(posxE, posyE);
  rotate(angE);
  
  fill(150);
  triangle(40, 0, 0,  25, 0, -25);
  fill(255,255,255);
  ellipse(0, 0, 50, 50);
  popMatrix();
}

void drawMine(){
  pushMatrix();
  translate(posx, posy);
  rotate(ang);
  
  keysAux();
  fill(150);
  triangle(40, 0, 0,  25, 0, -25);
  fill(255,255,255);
  ellipse(0, 0, 50, 50);
  if (vel >= 0){
    posx += cos(ang)*vel;
    posy += sin(ang)*vel;
    vel -= 0.1;
  }
  popMatrix();
}


void draw() {
  background(204);

  drawCrystals();
  
  drawEnemy();

  drawMine();
  
}

void keyPressed() {
  if(key == 'W' || key == 'w'){
    keys0 = true;
  }
  else if(key == 'E' || key == 'e'){
    keys2 = true;
  }
  else if(key == 'Q' || key == 'q'){
    keys1 = true;
  }

}

void keyReleased() {
  
  if(key == 'W' || key == 'w'){
    keys0 = false;
  }
  else if(key == 'E' || key == 'e'){
    keys2 = false;
  }
  else if(key == 'Q' || key == 'q'){
    keys1 = false;
    
  }
}
