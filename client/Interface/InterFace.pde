import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.io.*;
import java.net.*;


float posx = 0;
float posy = 0;
float posxE = 0;
float posyE = 0;
float angE = 0;
float ang = 0;
float vel = 0;
boolean keys1;
boolean keys2;
boolean keys0;
ArrayList < Float > objetos = new ArrayList < Float > ();
float cNum = 0;
boolean gameOver = false;
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
          try{
            String res ;
            while(!gameOver)
            {
              res = cm.receive("position");
              String[] sep = res.split(" ");
              posx =Integer.parseInt(sep[0]);
              posy =Integer.parseInt(sep[1]);
              ang = Integer.parseInt(sep[2]);
              posxE =Integer.parseInt(sep[3]);
              posyE = Integer.parseInt(sep[4]);
              angE = Integer.parseInt(sep[5]);
            }
          }catch(Exception e){
            
          }
        }).start();
      
    new Thread(() -> {
      try{
            String res ;
            while(!gameOver)
            {
              res = cm.receive("newObject");
              String[] vals = res.split(" ");
              String cor = vals[0];
              String x = vals[1];
              String y = vals[2];
              objetos.add(Float.parseFloat(cor)); 
              objetos.add(Float.parseFloat(x));
              objetos.add(Float.parseFloat(y));
            }
      }catch(Exception e){
        
      }
        }).start();

    new Thread(() -> 
    {
      try
      {
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
              gameOver = true;
            }
      }
      catch(Exception e)
      {

      }
        }).start();
}


 


void drawObjects(){
  /*
  cNum = 1;
  for (int i = 0; i< cNum;i++){
    quad(objetos[2*i]-25,objetos[2*i + 1]-25 ,objetos[2*i]+25,objetos[2*i + 1]-25,objetos[2*i]+25,objetos[2*i + 1]+25  ,objetos[2*i]-25,objetos[2*i + 1]+25);
  }
  */
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
  

  fill(150);
  triangle(40, 0, 0,  25, 0, -25);
  fill(255,255,255);
  ellipse(0, 0, 50, 50);
  popMatrix();
}


void draw() {
  background(204);
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
    public void send(String type ,String message) 
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
        String message = "";
        try 
        {  
          res = in.readLine();
          String[] array = res.split(":");
          typeMessage.put(array[0],array[1]);
          message = typeMessage.get(type);
          if (message.equals(null))
          {
            notifyAll();
            while(message.equals(null))
            {
              message = typeMessage.get(type);
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



