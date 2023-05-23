import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.io.*;
import java.net.*;
import java.util.Iterator;

public class Triplet
{
    private final Float first;
    private final Float second;
    private final Float third;

    public Triplet(Float first, Float second, Float third) 
    {
        this.first = first;
        this.second = second;
        this.third = third;
    }

    public boolean Equals(Float first, Float second, Float third)
    {
      return this.first == first && this.second == second && this.third == third;
    }

    public Float getFirst() { return first; }
    public Float getSecond() { return second; }
    public Float getThird() { return third; }
}

float posx ;
float posy ;
float posxE ;
float posyE ;
float angE ;
float ang ;
float vel ;
boolean keys1;
boolean keys2;
boolean keys0;
ArrayList < Triplet > objetos = new ArrayList < Triplet > ();
float cNum = 0;
boolean gameOver = false;
ConnectionManager cm;
Socket s;
int estado = 0;
// Variable to store text currently being typed
String input = "";

// Variable to store saved text when return is hit
String user = "";
String pass = "";
boolean ready = false;
boolean name = true;
boolean senha = false;

void starto(){
  
  String host = "localhost";
  int port = 1234;
    
  try{
      s = new Socket(host, port);
      cm = new ConnectionManager(s);
            
      cm.send("users", "create_account anotherone admin");
            
      new Thread(() -> {
          try {
              
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
  menu();

  keys0 = false;
  keys1 = false;
  keys2 = false;

    new Thread(() -> {
          try{
            String res ;
            while(!gameOver)
            {
              res = cm.receive("game");
              
             
              
              if(!(res == null))
              {
                //System.out.println("recebi posicao");
                //System.out.println(res+"pos");
                String[] sep = res.split(" ");
                if (sep[0].equals("position")){
                  posx =Float.parseFloat(sep[1]);
                  posy =Float.parseFloat(sep[2]);
                  ang = Float.parseFloat(sep[3]);
                  posxE =Float.parseFloat(sep[4]);
                  posyE = Float.parseFloat(sep[5]);
                  angE = Float.parseFloat(sep[6]);
                }
                else if (sep[0].equals("gameOver"))
                {
                  
                }
                else if (sep[0].equals("tiraObjeto"))
                {
                  Float cor = Float.parseFloat(sep[1]);
                  Float x = Float.parseFloat(sep[2]);
                  Float y = Float.parseFloat(sep[3]);
                  Iterator <Triplet> itr = objetos.iterator();
                  while (itr.hasNext())
                  {
                    Triplet test = itr.next();
                    if (test.Equals(cor,x,y))
                    {
                      itr.remove();
                    }
                  }
                }
                else 
                {
                  String cor = sep[1];
                  String x = sep[2];
                  String y = sep[3];
                  Triplet triplet = new Triplet(Float.parseFloat(cor),Float.parseFloat(x),Float.parseFloat(y));
                  objetos.add(triplet);
                
                }
              }
            }
          }
          catch(Exception e){
            System.out.println("Thread crashou POs");
          }
        }).start();
    /*
    new Thread(() -> {
      try{
            String res ;
            while(!gameOver)
            {
              
              res = cm.receive("object",9000);
              
              
              if (!(res == null))
              {
              //System.out.println("recebi objecto");
              //System.out.println(res+"object");
              String[] vals = res.split(" ");
              String cor = vals[0];
              String x = vals[1];
              String y = vals[2];
              objetos.add(Float.parseFloat(cor)); 
              objetos.add(Float.parseFloat(x));
              objetos.add(Float.parseFloat(y)); 
              }
            }
      }catch(Exception e){
        System.out.println("Thread crashou Object");
      }
        }).start();
    */
    /*
    new Thread(() -> 
    {
      try
      {
            String res ;
            while(!gameOver)
            {
              res = cm.receive("gameOver");
              System.out.println(res);
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
        System.out.println("Thread crashou");
      }
        }).start();
        */
}


 


void drawObjects(){
  /*
  cNum = 1;
  for (int i = 0; i< cNum;i++){
    quad(objetos[2*i]-25,objetos[2*i + 1]-25 ,objetos[2*i]+25,objetos[2*i + 1]-25,objetos[2*i]+25,objetos[2*i + 1]+25  ,objetos[2*i]-25,objetos[2*i + 1]+25);
  }
  */
  for (Triplet t : objetos)
  {
    fill(t.getFirst());
    ellipse(t.getSecond(), t.getThird(), 75, 75);
  }
}



void drawEnemy(){
  pushMatrix();
  translate(posxE, posyE);
  rotate(angE);
  
  fill(150);
  triangle(40, 0, 0,  25, 0, -25);
  fill(255,0,0);
  ellipse(0, 0, 50, 50);
  popMatrix();
}

void drawMine(){
  pushMatrix();
  
  translate(posx, posy);
  rotate(ang);
  

  fill(150);
  triangle(40, 0, 0,  25, 0, -25);
  fill(0,0,255);
  ellipse(0, 0, 50, 50);
  popMatrix();
}


void draw() {
  switch(estado){
    case 1:
      login();
      break;
    case 2:
      criarConta();
      break;
    case 3:
      esperaJogo();
      break;
    case 4:
      jogo();
      break;
    default :
      menu();
    break;		
  }
}

void menu(){
  int indent = 25;
  background(255,255,0);
  textSize(56);
  fill(50);
  text("Login - L ",indent,190);
  text("Criar conta - C",indent,230);
  /*
  if(ready){
    estado=3;
  }
  */
}

void login(){
  background(255,255,0);
  if (name)
  {
    text("Username: " + input,25,190);
    text("Password: " ,25,230);
  }
  else
  {
    text("Username: " + user,25,190);
    text("Password: " + input,25,230);
  }
  if(senha && user)
  {
    cm.send("users", "login " + user " " + pass + "\n");
            
    String res = cm.receive("Users");
    String[] dividido = res.split (":");
    if(dividido[1].equals("Sucessful"))
    {
      estado = 3;
    }
  }
}

void criarConta()
{
  background(255,255,0);
  if (name)
  {
    text("Username: " + input,25,190);
    text("Password: " ,25,230);
  }
  else
  {
    text("Username: " + user,25,190);
    text("Password: " + input,25,230);
  }
}

void esperaJogo(){
  background(255,255,0);
  text("Wait to begin game",100,500);
  if(key == ' '){
    estado=4;
  }
}

void jogo() {
  background(204);
  drawEnemy();
  drawMine();
  if(objetos.size() != 0)
    drawObjects();
}


//user
void keyPressed() {
  if(key == 'W' || key == 'w' && (estado == 4 ))
  {
    keys0 = true;
    cm.send("keyPressed","w");
  }
  else if(key == 'E' || key == 'e' && (estado == 4 )){
    keys2 = true;
    cm.send("keyPressed","e");
  }
  else if(key == 'Q' || key == 'q' && (estado == 4 )){
    cm.send("keyPressed","q");
    keys1 = true;
  }
  else if(key == 'C' || key == 'c' && (estado == 0 )){
    estado = 2;
  }
  else if((key == 'L' || key == 'l') && (estado == 0 )){
    estado = 1;
  }
  else if(key == '\n' && (estado == 1  || estado == 2 ) )
  {
    if (name)
    {
      user = input;
      name = false;
      input = "";

    }
    else
    {
      pass = input ;
      name = true;
      senha = true;
      input = "";
      
    }
    // A String can be cleared by setting it equal to ""
  }
  else {
    input = input + key;
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
    cm.send("keyReleased","q");
    
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
          while(message.equals(null)){ 
            
            
            message = typeMessage.get(type);
          }
            notifyAll();
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