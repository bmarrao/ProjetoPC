import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.io.*;
import java.net.*;
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

    public String receive(String type)throws IOException
    {
        String res = "";
        try
        {
            res = in.readLine();
            String[] arr = res.split(":");
            while (arr[0] != type) {
                res = in.readLine();
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

