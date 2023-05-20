import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.io.*;
import java.net.*;


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

ConnectionManager cm;
Socket s;

void starto(){
  
  String host = "localhost";
  int port = 1234;
    
  try{
      s = new Socket(host, port);
      cm = new ConnectionManager(s);
            
      cm.send("users", "create_account anotherone admin");
            
      new Thread(() -> {
          try {
              System.out.println("Qualquer coisa");
              String res = cm.receive("Users");
              System.out.println(res);
          }
          catch (Exception e) {
               // TODO: handle exception
          }
      }).start();
            
      }catch(Exception e){
         e.printStackTrace();
         System.exit(0);
      }
  }




void setup() {
  starto();
  size(1000, 1000);
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
//user
void keyPressed() {
  if(key == 'W' || key == 'w'){
    keys0 = true;
    cm.send("keyPressed","w");
  }
  else if(key == 'E' || key == 'e'){
    keys2 = true;
    cm.send("keyPressed","e");
  }
  else if(key == 'Q' || key == 'q'){
    cm.send("keyPressed","q");
    keys1 = true;
  }

}

void keyReleased() {
  
  if(key == 'W' || key == 'w'){
    keys0 = false;
    cm.send("keyReleased","w");
  }
  else if(key == 'E' || key == 'e'){
    keys2 = false;
    cm.send("keyReleased","e");

  }
  else if(key == 'Q' || key == 'q'){
    keys1 = false;
    cm.send("keyReleased","w");
    
  }
}

public class ConnectionManager
{
    Socket s;
    BufferedReader in;
    PrintWriter out ;
    public ConnectionManager(Socket socket) throws IOException
    {
        try
        {
            this.s = socket;
            this.in = new BufferedReader(new InputStreamReader(s.getInputStream()));
            this.out = new PrintWriter(s.getOutputStream());
        }
        catch(Exception e)
        {

        }

    }
    //Precisa ser synchonized
    public synchonized void send(String type ,String message) throws IOException
    {
        try
        {
            out.println(type + ":" + message);
            out.flush();
        }
        catch(Exception e)
        {

        }
    }

    public String receive(String type)throws IOException
    {
        String res = "";
        try
        {
            
            res = in.readLine();
            
            String[] arr = res.split(":");
            
            while(!type.equals(arr[0])) 
            {
                
                res = in.readLine();            
                arr = res.split(":");
            }   
        }
        catch(Exception e) {

        }
        

        return res ;
    }

    public void close() throws IOException
    {
        this.s.close();
    }
}



