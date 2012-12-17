import java.net.*;
import java.io.*;

public class DCSSServer {
    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = null;
        boolean listening = true;

        if (args.length != 2) {
			System.out.println("Usage DCSSServer <port> <input file>");
			return;
		}

        try {
            DCSProtocol.loadCommand( args[1] );
            int port = Integer.parseInt(args[0]);
            serverSocket = new ServerSocket(port);
        } catch (NumberFormatException e) {
            System.err.println("Invalid command-line argument");
            System.err.println("Usage: DCSSServer [port]");
            System.exit(-1);
        } catch (IOException e) {
            System.err.println(e.getMessage());
            System.exit(-1);
        }

        while (listening)
	    	new DCSSServerThread(serverSocket.accept()).start();

        serverSocket.close();
    }
}
