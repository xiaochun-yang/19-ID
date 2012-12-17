import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.Socket;
import java.io.PrintStream;

public class ChunkEncodingTests
{
	public static void main1(String args[]) {
	
		try {
		
		if (args.length != 5) {
			System.out.println("Usage: java ChunkEncodingTests <port> <user> <sessionId> <src file> <dest file>");
			return;
		}
		
		int port = Integer.parseInt(args[0]);
		String user = args[1];
		String sessionId = args[2];
		String src = args[3];
		String dest = args[4];
		String urlStr = "/writeFile?impUser=" + user 
					+ "&impSessionID=" + sessionId 
					+ "&impWriteBinary=true&impFilePath=" + dest;
					
		System.out.println("url = " + urlStr);
		
		Socket sock = new Socket("localhost", port);
		OutputStream out = sock.getOutputStream();
		PrintStream pstream = new PrintStream(out);
		StringBuffer request = new StringBuffer();
		pstream.println("POST " + urlStr + " HTTP/1.1");
		pstream.println("Host: localhost:61001");
		pstream.println("Content-Type: binary/octet-stream");
		pstream.println("Transfer-Encoding: chunked");
		pstream.println("");

		File srcFile = new File(src);
		FileInputStream fin = new FileInputStream(srcFile);
		int numRead = 0;
		byte buf[] = new byte[1024];
//		byte endOfLine[] = new byte[2];
//		endOfLine[0] = '\n'; endOfLine[1] = '\0';
		while ((numRead=fin.read(buf)) > -1) {
			pstream.println(Integer.toHexString(numRead));
			pstream.write(buf, 0, numRead);
			pstream.print("\n");
		}
		pstream.println("");
		fin.close();
		
		InputStream in = sock.getInputStream();
		while ((numRead = in.read(buf)) > -1) {
			System.out.write(buf, 0, numRead);
		}
		System.out.println("");
		out.close();
		
		} catch (Exception e) {
			e.printStackTrace();
		}	
	}
	
	public static void main(String args[]) {
	
		try {
		
		if (args.length != 5) {
			System.out.println("Usage: java ChunkEncodingTests <port> <user> <sessionId> <src file> <dest file>");
			return;
		}
		
		int port = Integer.parseInt(args[0]);
		String user = args[1];
		String sessionId = args[2];
		String src = args[3];
		String dest = args[4];
		String urlStr = "/writeFile?impUser=" + user 
					+ "&impSessionID=" + sessionId 
					+ "&impWriteBinary=true&impFilePath=" + dest;
					
		System.out.println("url = " + urlStr);
		
		Socket sock = new Socket("localhost", port);
		OutputStream out = sock.getOutputStream();
		PrintStream pstream = new PrintStream(out);

		pstream.println("POST " + urlStr + " HTTP/1.1");
		pstream.println("Host: localhost:61001");
		pstream.println("Content-Type: binary/octet-stream");
		pstream.println("Transfer-Encoding: chunked");
		pstream.println("");

		writeChunk(pstream, 'A', 30);
		writeChunk(pstream, 'B', 20);
		writeChunk(pstream, 'C', 15);
		pstream.println("0");
				
		InputStream in = sock.getInputStream();
		int numRead;
		byte buf[] = new byte[100];
		while ((numRead = in.read(buf)) > -1) {
			System.out.write(buf, 0, numRead);
		}
		System.out.println("");
		out.close();
		sock.close();
		
		} catch (Exception e) {
			e.printStackTrace();
		}	
	}

	private static void writeChunk(PrintStream pstream, char letter, int numBytes) throws Exception {
		byte[] buf = new byte[numBytes];
		for (int i = 0; i < numBytes; ++i) {
			buf[i] = (byte)letter;
		}
		pstream.println(Integer.toHexString(numBytes));
		pstream.write(buf, 0, numBytes);
		pstream.print("\n");	
	}
}

