import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.io.*;
import java.net.*;
import java.util.Iterator;

public class Triplett
{
    private final float  first;
    private final Float second;
    private final Float third;

    public Triplett(Float first, Float second, Float third) 
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

boolean contaCriadaSucess = false;
boolean contaCriadaNoSucess = false;
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
String resultado = "";
boolean keys0;
ArrayList < Triplett > objetos = new ArrayList < Triplett > ();
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
  Triplett triplet = new Triplett(1.0,-500.0,-500.0);
  objetos.add(triplet);

  try{
      s = new Socket(host, port);
      cm = new ConnectionManager(s);
      cm.send("scoreBoard","scoreboard");
      new Thread(() -> 
      {
        try 
        {
          String res = cm.receive("Scoreboard");
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
              estado = 4;
              if(!(res == null))
              {
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
                  once2 = true;
                  resultado = sep[1];
                  estado = 8;
                  gameOver = true;
                }
                else if (sep[0].equals("tiraObjeto")){
                  Float cor = Float.parseFloat(sep[1]);
                  Float x = Float.parseFloat(sep[2]);
                  Float y = Float.parseFloat(sep[3]);
                  
                  int n = 0;
                  int aux = 0;
                  for(Triplett t : objetos){
                        
                    if ((Float.compare(t.getSecond() , x)== 0)&&(Float.compare(t.getThird() , y)== 0) && (Float.compare(t.getFirst() , cor)== 0)) aux = n;
                    n++;
                  }
                  objetos.remove(aux);
                }
                else 
                {
                  String cor = sep[1];
                  String x = sep[2];
                  String y = sep[3];
                  Triplett triplet = new Triplett(Float.parseFloat(cor),Float.parseFloat(x),Float.parseFloat(y));
                  objetos.add(triplet);
                
                }
              }
            }
          }
          catch(Exception e){
            gameThread();
          }
        }).start();
}

void drawObjects(){
  for (Triplett t : objetos)
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
    cm.send("users", "find_game " + user + "\n");
      new Thread(() -> {
            try {
                
                String res = cm.receive("Users");
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
    case 8:
      acabou();
      break;
    default :
      menu();
    break;		
  }
}

void acabou()
{
  background(255,255,0);
  text(resultado,400,400);

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
    cm.send("users", "close_account " + user + " " + pass );
    new Thread(() -> {
          try {
              
              String res = cm.receive("Users");
              if(res.equals("sucessful"))
              {
                System.exit(0);
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
  if(contaCriadaSucess){
    text("Conta criada com sucesso!" ,100,400);
  }
  else if(contaCriadaNoSucess){
    text("Conta não foi criada, tente de novo!" ,100,400);
  }
  else if (name)
  {
    text("Username: " + input,25,190);
    text("Password: " ,25,230);
  }
  else
  {
    text("Username: " + user,25,190);
    text("Password: " + input,25,230);
  }
  if( senha && name && once )
  {
    once = false;

    cm.send("users", "create_account " + user + " " + pass + "\n");
    new Thread(() -> {    
        try {
              
          String res = cm.receive("Users");
          if(res.equals("sucessful"))
          {
            contaCriadaSucess = true;
          }
          else{
            contaCriadaNoSucess = true;
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
    public synchronized void send(String type ,String message) 
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