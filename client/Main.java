import java.net.Socket;

public class Main {
    public static void main(String[] args) {
        if(args.length<2)
            System.exit(1);
        String host = args[0];
        int port = Integer.parseInt(args[1]);
    
        try{
            Socket s = new Socket(host, port);
            ConnectionManager cm = new ConnectionManager(s);
            
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
}
