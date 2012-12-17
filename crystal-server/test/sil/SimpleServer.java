package sil;

import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.ServerSocket;
import java.net.Socket;

public class SimpleServer {

	public static void main(String args[]) {
		
		try {
		
		ServerSocket server = new ServerSocket(9999);
		Socket client = server.accept();
		InputStream in = client.getInputStream();
		byte buf[] = new byte[500];
		int num = -1;
		
		FileOutputStream out = new FileOutputStream("out.http");
		while ((num=in.read(buf, 0, 500)) > -1) {
			if (num > 0)
				out.write(buf, 0, num);
		}
		out.close();
		
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
