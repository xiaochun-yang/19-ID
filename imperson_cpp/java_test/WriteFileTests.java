import java.io.*;
import java.net.*;

public class WriteFileTests
{
	public static void main(String args[]) {
	
		try {
			if (args.length != 5) {
				System.out.println("java WriteFileTests <port> <user> <sessionId> <src file> <dest file>");
				return;
			}
		
			int port = Integer.parseInt(args[0]);
			String user = args[1];
			String sessionId = args[2];
			String srcFile = args[3];
			String destFile = args[4];
			
			Socket sock = new Socket("localhost", port);
			OutputStream out = sock.getOutputStream();
			PrintStream pstream = new PrintStream(out);
			
			File imageFile = new File(srcFile);
			long len = imageFile.length();	


			// Http request line and headers
			pstream.println("POST /writeFile?impUser=" + user + "&impSessionID=" + sessionId
					+ "&impFilePath=" + destFile
					+ "&impWriteBinary=true&impBackupExist=true HTTP/1.1");
			pstream.println("Host: localhost:" + port);
			pstream.println("Content-Type: binary/octet-stream");
			pstream.println("Content-Length: " + len);
			pstream.println("Connection: close");
			pstream.println("");			
						
							
			byte[] buf = new byte[2048];
			FileInputStream in = new FileInputStream(srcFile);
			int numRead = 0;
			while ((numRead=in.read(buf)) > -1) {
				pstream.write(buf, 0, numRead);
			}
			pstream.flush();
			in.close();
			
			InputStream sin = sock.getInputStream();
			while ((numRead=sin.read(buf)) > -1) {
				System.out.write(buf, 0, numRead);
			}
			System.out.println("");
			pstream.close();
			sin.close();
			sock.close();
				
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	
}

