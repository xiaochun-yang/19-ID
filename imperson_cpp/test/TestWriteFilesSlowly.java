import java.io.*;
import java.net.*;

// Test writeFiles slowly. writeFiles command show write file to a tmp file name until it finishes writing the file
// and then rename the file to the designated file name. This is to prevent other process from reading the file
// to early. Look for the tmp file while running this test before the writing is done.
public class TestWriteFilesSlowly {

	public static String getUser() {
		return System.getenv("USER");
	}

	public static String getSessionId() throws Exception {
		BufferedReader in = new BufferedReader(new FileReader("/home/" + getUser() + "/.bluice/session"));
		String sessionId = in.readLine().trim();
		in.close();
		return sessionId;
	}

	public static void main(String[] args) {
		if (args.length == 0) {
			System.out.println("Usage: java TestWriteFilesSlowly <input image file>");
			return;
		}

		try {
			String user = getUser();
			String sessionId = getSessionId();
			
			String inputFile = "/data/" + user + "/saved_slow_1_0001.img";

			// Get file size
			FileInputStream in = new FileInputStream(inputFile);
			int bufSize = 4096;
			byte buf[] = new byte[bufSize];
			int fileSize = 0;
			int count = 0;
			while ((count = in.read(buf)) > 0) {
				fileSize += count;
			}
			in.close();

			String endOfLine = "\n";
			// Connect to imp server and send writeFiles request
			Socket sock = new Socket("localhost", 61001);
			sock.setSoTimeout(0); // Wait infinitely
			OutputStream sOut = sock.getOutputStream();
			BufferedReader sIn = new BufferedReader(new InputStreamReader(sock.getInputStream()));

			StringBuffer request = new StringBuffer();
			request.append("POST /writeFiles?impUser=" + user + "&impSessionID=" + sessionId + " HTTP/1.1" + endOfLine);
			request.append("Host: localhost:61001" + endOfLine);
			request.append("Content-Type: binary" + endOfLine);
			request.append(endOfLine);
			request.append("/data/" + user + "/slow_1_0001.img" + endOfLine);
			request.append(fileSize + endOfLine);
			sOut.write(request.toString().getBytes(), 0, request.length());

			System.out.println(request.toString());

			// Read file again and write content of file in HTTP body slowly.
			in = new FileInputStream(inputFile);
			count = 0;
			int total = 0;
			while ((count = in.read(buf)) > 0) {
				sOut.write(buf, 0, count);
				total += count;
				System.out.println("Written " + count + " bytes, total = " + total + " bytes");
				// Slow down file writing with sleep
				Thread.sleep(1000);
			}
			sOut.write(endOfLine.getBytes(), 0, endOfLine.length());
			System.out.println("Done reading and writing file");
			in.close();
			//sOut.close();
			sock.shutdownOutput();

			// Read HTTP response
			String line = null;
			while ((line = sIn.readLine()) != null) {
				System.out.println(line);
			}
			sock.close();

		} catch (Exception e) {
			e.printStackTrace();
		}	

	}

}
