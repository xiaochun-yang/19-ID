import java.io.*;
import java.net.*;

public class PilatusDhs
{
	public static void main(String args[]) {
	
		try {
			if (args.length != 7) {
				System.out.println("java PilatusDhs <host> <port> <user> <sessionId> <src image file> <dest dir> <num files to write>");
				return;
			}

			long startTime = System.currentTimeMillis();
		
			String host = args[0];
			int port = Integer.parseInt(args[1]);
			String user = args[2];
			String sessionId = args[3];
			String imagePath = args[4];
			String dest = args[5];
			int maxFiles = Integer.parseInt(args[6]);
			
			String rootName = "pilatus";

			// Load image file to memory
			int bufSize = 2048;
			byte[] buf = new byte[bufSize];
			File imageFile = new File(imagePath);
			FileInputStream fin = new FileInputStream(imageFile);
			ByteArrayOutputStream bout = new ByteArrayOutputStream();
			int numRead = 0;
			while ((numRead=fin.read(buf)) > -1) {
					bout.write(buf, 0, numRead);
			}
			fin.close();
			byte[] imageBuf = bout.toByteArray();	
			System.out.println("Image file " + imageFile.getPath() + " size = " + imageFile.length() + " image buf size = " + imageBuf.length);
			
			final Socket sock = new Socket(host, port);
			OutputStream out = sock.getOutputStream();
			PrintStream pstream = new PrintStream(out);

			// Http request line and headers
			String endOfLine = "\n";
			pstream.print("POST /writeFiles?impUser=" + user + "&impSessionID=" + sessionId + "&impWriteBinary=true&impBackupExist=true HTTP/1.1" + endOfLine);
			pstream.print("Host: " + host + ":" + port + endOfLine);
			pstream.print("Content-Type: binary/octet-stream" + endOfLine);
			pstream.print("Connection: close" + endOfLine);
			pstream.print(endOfLine);	

			boolean asynchronousRead = false;
						
			Thread responseThread = null;
			if (asynchronousRead) {

				final InputStream in = sock.getInputStream();
				// A nthread to keep reading http response
				responseThread = new Thread() {
					public void run() {

						try {
							int numRead;
							byte[] buf = new byte[2048];
							while ((numRead=in.read(buf)) > -1) {
								System.out.write(buf, 0, numRead);
							}
							System.out.println("");
						} catch (Exception e) {
							System.out.println("Error in response thread");
							e.printStackTrace();
						}
					}
				};
				responseThread.start();	
			}

			int curRead;
			byte curByte = '\0';
			int curPos = 0;
			int maxSize = 65536; // 64K
			byte[] inBuf = new byte[maxSize];
			boolean gotHeader = false;
			BufferedReader reader = null;
			if (!asynchronousRead)
				reader = new BufferedReader(new InputStreamReader(sock.getInputStream()));

			int count = 1;
			while (count <= maxFiles) {
											
					String fileIndex;
					if (count < 10)
						fileIndex = "000" + String.valueOf(count);
					else if (count < 100)
						fileIndex = "00" + String.valueOf(count);
					else if (count < 1000)
						fileIndex = "0" + String.valueOf(count);
					else
						fileIndex = String.valueOf(count);
					
					String destFile = dest + "/" + rootName + "_" + fileIndex + ".cbf";
										
					// Http body. Each file starts with 2 lines of
					// filename and file size. Third line is the 
					// binary content.
					// Followed by an end of line charactor.

					int len = imageBuf.length;
					int written = 0;
					int chunkSize = bufSize;
					pstream.print(destFile + endOfLine);
					pstream.print(String.valueOf(imageBuf.length) + endOfLine);
					if (len > 0) {
						while (written < len) {
							chunkSize = (len - written) < bufSize ? len - written : bufSize;
							pstream.write(imageBuf, written, chunkSize);
							written += chunkSize;
						}
						pstream.print(endOfLine);
						pstream.flush();
					}

//					System.out.println("DEBUG: finished sending file " + destFile);

					// Read response until we find an end of line
					if (!asynchronousRead) {

						String line;
						// Read until we got all the header lines
						// Wait for socket we have to.
						while (!gotHeader && ((line=reader.readLine()) != null)) {
							line = line.trim();
							System.out.println(line);
							if (line.length() == 0) {
								gotHeader = true;
							}
						}
						// Expect to read at least one line per file.
//						System.out.println("Waiting for response for line for file " + destFile);
						line = reader.readLine();
						// End of response
						if (line == null)
							break;
						line = line.trim();
						System.out.println(line);
						// Response for each written file starts with warning lines
						// The last line starts with OK.
						while (!line.startsWith("OK")) {
							System.out.println("DEBUG: reading for lines");
							// Expect to read at least one line per file.
							line = reader.readLine();
							if (line == null)
								break;
							line = line.trim();
							System.out.println(line);
						}
//						System.out.println("DEBUG: finished reading response for this file");
					}
//					System.out.println("DEBUG: finished reading response for file " + destFile);

					++count;
			}
			
			sock.shutdownOutput();
			
			if (asynchronousRead) {
				while (responseThread.isAlive()) {
					Thread.sleep(1000);
				}
			}
						
			pstream.close();
			if (!asynchronousRead && reader != null)
				reader.close();
			sock.close();

			long endTime = System.currentTimeMillis();
			long totTimeSec = (endTime - startTime)/1000;
			System.out.println("Writing " + maxFiles + " took " + totTimeSec + " seconds.");
				
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
/*
	public static void main2(String args[]) {
	
		try {
			if (args.length != 6) {
				System.out.println("java PilatusDhs <port> <user> <image dir> <dest dir> <num files to write>");
				return;
			}

			long startTime = System.currentTimeMillis();
		
			int port = Integer.parseInt(args[0]);
			String user = args[1];
			String sessionId = args[2];
			String src = args[3];
			String dest = args[4];
			int maxFiles = Integer.parseInt(args[5]);
			
			String rootName = "pilatus";

			File imageDir = new File(src);
			File[] imageFiles = imageDir.listFiles();
			if (imageFiles.length == 0) {
				System.out.println("Dir " + src + " contains no cbf file.");
				return;
			}
			
			final Socket sock = new Socket("localhost", port);
			OutputStream out = sock.getOutputStream();
			PrintStream pstream = new PrintStream(out);

			// Http request line and headers
			pstream.println("POST /writeFiles?impUser=" + user + "&impSessionID=" + sessionId + "&impWriteBinary=true&impBackupExist=true HTTP/1.1");
			pstream.println("Host: localhost:" + port);
			pstream.println("Content-Type: binary/octet-stream");
			pstream.println("Connection: close");
			pstream.println("");	
						
			final InputStream in = sock.getInputStream();

			// A nthread to keep reading http response
			Thread responseThread = new Thread() {
				public void run() {

					try {
						int numRead;
						byte[] buf = new byte[2048];
						while ((numRead=in.read(buf)) > -1) {
							System.out.write(buf, 0, numRead);
						}
						System.out.println("");

					} catch (Exception e) {
						System.out.println("Error in response thread");
						e.printStackTrace();
					}
				}
			};

			responseThread.start();	
			
			byte[] buf = new byte[2048];
			int count = 1;
			while (count <= maxFiles) {
						
				for (int i = 0; (i < imageFiles.length) && (count <= maxFiles); ++i) {
					File imageFile = imageFiles[i];
					if (!imageFile.getName().endsWith(".cbf"))
						continue;
					
					String fileIndex;
					if (count < 10)
						fileIndex = "000" + String.valueOf(count);
					else if (count < 100)
						fileIndex = "00" + String.valueOf(count);
					else if (count < 1000)
						fileIndex = "0" + String.valueOf(count);
					else
						fileIndex = String.valueOf(count);
					
					String destFile = dest + "/" + rootName + "_" + fileIndex + ".cbf";
										
					// Http body. Each file starts with 2 lines of
					// filename and file size. Third line is the 
					// binary content.
					// Followed by an end of line charactor.
					pstream.println(destFile);
					pstream.println(imageFile.length());
					if (imageFile.length() > 0) {	
						FileInputStream fin = new FileInputStream(imageFile);
						int numRead = 0;
						while ((numRead=fin.read(buf)) > -1) {
							pstream.write(buf, 0, numRead);
						}
						fin.close();
						pstream.print("\n");
						pstream.flush();
					}
					++count;
				}
			}
			
			sock.shutdownOutput();
			
			while (responseThread.isAlive()) {
				Thread.sleep(1000);
			}
						
			pstream.close();
			in.close();
			sock.close();

			long endTime = System.currentTimeMillis();
			long totTimeSec = (endTime - startTime)/1000;
			System.out.println("Writing " + maxFiles + " took " + totTimeSec + " seconds.");
				
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	public static void main1(String args[]) {
	
		try {
			if (args.length != 6) {
				System.out.println("java PilatusDhs <port> <user> <image dir> <dest dir> <num files to write>");
				return;
			}
		
			int port = Integer.parseInt(args[0]);
			String user = args[1];
			String sessionId = args[2];
			String src = args[3];
			String dest = args[4];
			int maxFiles = Integer.parseInt(args[5]);
			
			String rootName = "pilatus";

			File imageDir = new File(src);
			File[] imageFiles = imageDir.listFiles();
			if (imageFiles.length == 0) {
				System.out.println("Dir " + src + " contains no cbf file.");
				return;
			}
			
			// Http request line and headers
			System.out.println("POST /writeFiles?impUser=" + user + "&impSessionID=" + sessionId + "&impWriteBinary=true&impBackupExist=true HTTP/1.1");
			System.out.println("Host: localhost:" + port);
			System.out.println("Content-Type: binary/octet-stream");
			System.out.println("");			
			
			byte[] buf = new byte[2048];
			int count = 1;
			while (count <= maxFiles) {
						
				for (int i = 0; (i < imageFiles.length) && (count <= maxFiles); ++i) {
					File imageFile = imageFiles[i];
					if (!imageFile.getName().endsWith(".cbf"))
						continue;
					
					String fileIndex;
					if (count < 10)
						fileIndex = "000" + String.valueOf(count);
					else if (count < 100)
						fileIndex = "00" + String.valueOf(count);
					else if (count < 1000)
						fileIndex = "0" + String.valueOf(count);
					else
						fileIndex = String.valueOf(count);
					
					String destFile = dest + "/" + rootName + "_" + fileIndex + ".cbf";
					
					// Http body. Each file starts with 2 lines of
					// filename and file size. Third line is the 
					// binary content.
					// Followed by an end of line charactor.
					System.out.println(destFile);
					System.out.println(imageFile.length());
						
					FileInputStream in = new FileInputStream(imageFile);
					int numRead = 0;
					while ((numRead=in.read(buf)) > -1) {
						System.out.write(buf, 0, numRead);
					}
					System.out.println("");
					in.close();
					++count;
				}
			}
				
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	*/
	
}

