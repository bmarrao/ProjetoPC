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
float[] objetos = new float[16];
float cNum = 0;
boolean gameOver = False;
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
      cm.send("users", "login anotherone admin");
            
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
  new Thread(() -> {
          String res ;
          while(!gameOver)
          {
            res = cm.receive("position");
            String[] sep = res.split(" ");
            drawMine(Integer.parseInt(sep[0]),Integer.parseInt(sep[1]));
            drawEnemy(Integer.parseInt(sep[2]),Integer.parseInt(sep[3]));
          }
      }).start();
    
  new Thread(() -> {
          String res ;
          while(!gameOver)
          {
            res = cm.receive("newObject");
            String[] vals = res.split(" ");
            String cor = vals[0];
            String x = vals[1];
            String y = vals[2];
            objetos.append(Integer.parseInt(cor));
            objetos.append(Integer.parseInt(x));
            objetos.append(Integer.parseInt(y));
          }
      }).start();

  new Thread(() -> {
          String res ;
          while(!gameOver)
          {
            res = cm.receive("gameOver");
            if (res.equals("won"))
            {
              // 
            }
            else
            {
              //
            }
            gameOver = True;
          }
      }).start();

}


void drawObjects(){
  cNum = 1;
  for (int i = 0; i< cNum;i++){
    quad(objetos[2*i]-25,objetos[2*i + 1]-25 ,objetos[2*i]+25,objetos[2*i + 1]-25,objetos[2*i]+25,objetos[2*i + 1]+25  ,objetos[2*i]-25,objetos[2*i + 1]+25);
  }
}

void drawEnemy(int x, int y, int ang){
  pushMatrix();
  translate(x, y);
  rotate(ang);
  
  fill(150);
  triangle(40, 0, 0,  25, 0, -25);
  fill(255,255,255);
  ellipse(0, 0, 50, 50);
  popMatrix();
}

void drawMine(int x, int y, int ang){
  pushMatrix();
  
  translate(x, y);
  rotate(ang);
  
  keysAux();
  fill(150);
  triangle(40, 0, 0,  25, 0, -25);
  fill(255,255,255);
  ellipse(0, 0, 50, 50);
  popMatrix();
}


void draw() {
  background(204);

  drawObject();
  
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

    HashMap<String, String> typeMessage = new HashMap<String, String>();
    
    public ConnectionManager(Socket socket) throws IOException
    {
        try {
            this.s = socket;
            this.in = new BufferedReader(new InputStreamReader(s.getInputStream()));
            this.out = new PrintWriter(s.getOutputStream());
        }
        catch(Exception e)
        {

        }

    }
    public void send(String type ,String message) throws IOException
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

    public synchronized String receive(String type)throws IOException
    {
        String res = "";
        try 
        {  
          res = in.readLine();
          String[] array = res.split(":");
          typeMessage.put(arr[0],arr[1]);
          String message = typeMessage.get(type);
          if (!message)
          {
            notifyAll();
            while(!message)
            {
              message = typeMessage.get(type)
              wait();
            }
          }
        typeMessage.remove(type);
        }
        catch(Exception e) {

        }
        

        return message ;
    }

    public void close() throws IOException{
        this.s.close();
    }
}



