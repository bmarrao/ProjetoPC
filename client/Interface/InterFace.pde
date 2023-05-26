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

boolean scoreOnce = true;
boolean waiting = true;
boolean waitGame = true;
boolean once = true;
boolean once2 = true;
float posx ;
float posy ;
float posxE ;
float posyE ;
float angE ;
float ang ;
float vel ;
boolean keys1;
boolean keys2;
String [] scores;
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

void starto()
{
  
  String host = "localhost";
  int port = 1234;

  try{
      s = new Socket(host, port);
      cm = new ConnectionManager(s);
      cm.send("scoreBoard","scoreboard");
      new Thread(() -> 
      {
        try 
        {
          System.out.println("ola antes");
          String res = cm.receive("Scoreboard");
          System.out.println(res);
          System.out.println("ola depois");
          scores = res.split(" ");
          int num = Integer.parseInt(scores[0]);
          for (int i = 0 ; i < num; i++)
          {
            text("User " + scores[i*2+1] + "Vitorias: " + scores[i*2+2],100,300 * (i+1));
          } 
        }
        catch (Exception e) 
        {
          // TODO: handle exception
        }
      }).start();

      }catch(Exception e){
         e.printStackTrace();
         System.exit(0);
      }

}





void setup() 
{
  starto();
  size(1000, 1000);
  noStroke();
  menu();

  keys0 = false;
  keys1 = false;
  keys2 = false;
}


 
void gameThread()
{
   new Thread(() -> {
          try{
            String res ;
            while(!gameOver)
            {
              res = cm.receive("game");
              System.out.println(res);
              estado = 4;
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
                  System.out.println("OIIIIII");
                  once2 = true;
                  text(sep[1],300,300);
                  estado = 6;
                  gameOver = true;
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
}

void drawObjects(){
  for (Triplet t : objetos)
  {
    if (t.getFirst() == 1)
    {
      fill(255,0,0);
    }
    else if (t.getFirst() == 2)
    {
      fill(0,255,0);
    }
    else 
    {
      fill(0,0,255);
    }
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

void querJogar()
{
  background(255,255,0);
  text("Press space to find game",100,500);
  
  if (key == ' ' && once2 )
  {
    once2 = false;
    System.out.println("users" + "find_game " + user + "\n");
    cm.send("users", "find_game " + user + "\n");
      new Thread(() -> {
            try {
                
                String res = cm.receive("Users");
                System.out.println(res);
                if(res.equals("sucessful"))
                {
                  estado = 3;
                }
            }
            catch (Exception e) {
                // TODO: handle exception
            }
        }).start();
  }
  
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
    case 5:
      scoreboard();
      break;
    case 6:
      querJogar();
      break;
    case 7:
      fecharConta();
      break;
    default :
      menu();
    break;		
  }
}

void fecharConta()
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
   if(senha && name && once)
  {
    once = false;
    cm.send("users", "create_account " + user + " " + pass + "\n");
    new Thread(() -> {
          try {
              
              String res = cm.receive("Users");
              if(res.equals("sucessful"))
              {
                estado = 0;
              }
          }
          catch (Exception e) {
               // TODO: handle exception
          }
      }).start();
  }
}
void menu(){
  int indent = 30;
  background(255,255,0);
  textSize(56);
  fill(50);
  text("Login - L ",indent,200);
  text("Criar conta - C",indent,260);
  text("Scoreboard - S",indent,320);
  text("Fechar conta - F",indent,380);
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
  if(senha && name && once)
  {
    once = false;
    cm.send("users", "login " + user + " " + pass + "\n");
    new Thread(() -> {
          try {
              
              String res = cm.receive("Users");
              if(res.equals("sucessful"))
              {
                estado = 6;
              }
          }
          catch (Exception e) {
               // TODO: handle exception
          }
      }).start();
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
  if( senha && name && once)
  {
    once = false;

    cm.send("users", "create_account " + user + " " + pass + "\n");
    System.out.println("outro ola" + user + pass + "Oi" );
    new Thread(() -> {    
        try {
              
          String res = cm.receive("Users");
          System.out.println(res + name);
          System.out.println(res.equals("sucessful\n"));
          if(res.equals("sucessful\n"))
          {
            System.out.println("entrei aqui");
            estado = 6;
          }
        }
        catch (Exception e) {
               // TODO: handle exception
        }
      }).start();
  
    cm.send("login", "login " + user + " " + pass + "\n");
            
      new Thread(() -> {
          try {
             
               String res = cm.receive("Users");
                System.out.println(res);
                if(res.equals("sucessful"))
                {
                  System.out.println("entrei aqui");
                  estado = 3;
                }
          }
          catch (Exception e) {
               // TODO: handle exception
          }
      }).start();
            
  }
}

void esperaJogo(){
  background(255,255,0);
  text("Wait to begin game",100,500);

  gameOver = false;
  if (waitGame)
  {
    waitGame = false;
    gameThread();
  }

}

void jogo() {
  background(204);
  drawEnemy();
  drawMine();
  estado = 4;

  if(objetos.size() != 0)
    drawObjects();

}

void scoreboard()
{
  background(255,255,0);
  text("Scoreboard",100,200);
    int num = Integer.parseInt(scores[0]);
    for (int i = 0 ; i < num; i++)
    {
      text("User: " + scores[i*2+1],100,360  +(i * 60));
      text("Vitorias: " + scores[i*2+2],600,360  +(i * 60));
    } 
  text("Para sair aperte X",100,900);
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
  else if((key == 'S' || key == 's') && (estado == 0 ))
  {
    cm.send("keyPressed","w");

    estado = 5;
  }
  else if((key == 'X' || key == 'x') && (estado == 5 )){
    estado = 0;
    menu();
  }
  else if((key == 'F' || key == 'f') && (estado == 0 )){
    estado = 7;
  }
  else if(key == '\n' && (estado == 1  || estado == 2 || estado == 7) )
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