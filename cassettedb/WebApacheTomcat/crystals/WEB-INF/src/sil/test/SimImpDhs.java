package sil.test;

import java.util.*;
import java.net.*;
import java.io.*;
import javax.net.ssl.*;
import java.security.*;
import javax.net.SocketFactory;

public class SimImpDhs extends Thread
{
	private boolean done = false;
	private String beamline = "";
	private String silId = "";
	
	private String baseUrl = "";
	// SSL_RSA_WITH_RC4_128_MD5 or TLS_DHE_RSA_WITH_AES_128_CBC_SHA
	private String ciphers[] = null;
	
	private Properties config = new Properties();
		
	/**
	 */
	static public void main(String args[])
	{
		try {
					
		if (args.length < 1) {
			log("Got " + args.length + " arguments.");
			log("Usage: java sil.test.SimImpDhs <beamline> [getCassetteData|getLatestEventId|getSilIdAndEventId]");
      			// Get a Socket factory 
      			SSLSocketFactory factory = (SSLSocketFactory)SSLSocketFactory.getDefault(); 
			String[] supportedCiphers = factory.getSupportedCipherSuites();
			String tt = "";
			System.out.println("Supported ciphers:");
			for (int i = 0; i < supportedCiphers.length; ++i) {
				if (supportedCiphers[i].startsWith("TLS"))
					System.out.println("\t" + supportedCiphers[i]);
			}
			return;
		}
				
		SimImpDhs dcss = new SimImpDhs(args[0]);

		if (args.length > 1) {
			dcss.execute(args[1]);
			log("Exit");
			return;
		}
		
		
		dcss.start();
		
		while (dcss.isDone()) {
			sleep(5);
		}
		
		} catch (Exception e) {
			log("Exception in main: " + e.getMessage());
		}
	}

	/**
	 */
	public SimImpDhs(String b)
		throws Exception
	{		
		FileInputStream s = new FileInputStream("config.prop");
		config.load(s);
		
		beamline = b;
		
		silId = config.getProperty(beamline + ".silId");
		baseUrl = config.getProperty("baseUrl");
		String c = config.getProperty("ciphers");
		if ((c != null) && (c.length() > 0)) {
			StringTokenizer tok = new StringTokenizer(c, ":");
			int count = tok.countTokens();
			if (count > 0) {
				ciphers = new String[count];
				for (int i = 0; i < count; ++i) {
					ciphers[i] = tok.nextToken();
				}
			}
		}
	}

	/**
	 */
	public synchronized boolean isDone()
	{
		return done;
	}

	/**
	 */
	public synchronized void setDone()
	{
		done = true;
	}


	/**
	 */
	static private void log(String s)
	{
		System.out.println("SimDcss " + s);
	}
	
	/**
	 */
	public void execute(String command)
		throws Exception
	{
		String req1 = baseUrl + "/getCassetteData.do?forBeamLine=" + beamline;
		String req2 = baseUrl + "/getSilIdAndEventId.do?forBeamLine=" + beamline;
		String req3 = baseUrl + "/getLatestEventId.do?silId=" + silId;
		if (command.equals("getCassetteData")) {
			sendRequest(req1, "getCassetteData");
		} else if (command.equals("getSilIdAndEventId")) {
			sendRequest(req2, "getSilIdAndEventId");
		} else if (command.equals("getLatestEventId")) {
			sendRequest(req3, "getLatestEventId");
		} else {
			throw new Exception("Unsupported command " + command);
		}
	}

	/**
	 */
	public void run()
	{
		try {
		
			String req1 = baseUrl + "/getCassetteData.do?forBeamLine=" + beamline;
			String req2 = baseUrl + "/getSilIdAndEventId.do?forBeamLine=" + beamline;
			String req3 = baseUrl + "/getLatestEventId.do?silId=" + silId;

			while (!isDone()) {
				log("Beamline: " + beamline);
				sendRequest(req1, "getCassetteData");
				sendRequest(req2, "getSilIdAndEventId");
				if (!silId.equals("0"))
					sendRequest(req3, "getLatestEventId");
				sleep(1000);
			}

		} catch (Exception e) {
			log("Error in run: " + e.toString());
			e.printStackTrace();
		}
	}
	
	private void sendRequest(String urlStr, String logMsg)
	{
		
		try {
		
			int pos1 = baseUrl.indexOf("//");
			int pos2 = baseUrl.indexOf(":", pos1);
			int pos3 = baseUrl.indexOf("/", pos2);
			String host = baseUrl.substring(pos1+2, pos2);
			int port = Integer.parseInt(baseUrl.substring(pos2+1, pos3));

/*		
           		// Get a KeyStore object from the SSLConfiguration object.
           		char[] password = "changeit".toCharArray();
   			KeyStore ks = KeyStore.getInstance("JKS");
			ks.load(new FileInputStream("cacerts"), password);

            		// Allocate and initialize a KeyManagerFactory.
            		KeyManagerFactory kmf = KeyManagerFactory.getInstance("sunX509");
           		kmf.init(ks, password);
			
			// Allocate and initialize a TrustManagerFactory.
           		TrustManagerFactory tmf = TrustManagerFactory.getInstance("sunX509");
           		tmf.init(ks);
			
			// Allocate and initialize an SSLContext.
			SSLContext ctx = SSLContext.getInstance("TLS");
			ctx.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);
			SSLSocketFactory factory = ctx.getSocketFactory();
*/			
      			// Get a Socket factory 
      			SSLSocketFactory factory = (SSLSocketFactory)SSLSocketFactory.getDefault(); 
			SSLSocket sock = (SSLSocket)factory.createSocket(host, port);
			sock.setUseClientMode(true);
//			sock.setKeepAlive(false);
			if (ciphers != null)
				sock.setEnabledCipherSuites(ciphers);
			
			sock.setSoTimeout(10000);
			sock.startHandshake();
			
      			BufferedWriter out = new BufferedWriter(new OutputStreamWriter(sock.getOutputStream()));
			String msg = "GET " + urlStr + " HTTP/1.1\n"
					+ "Host: " + host + ":" + port + "\n"
					+ "Connection: close\n\n";
			out.write(msg);
			out.flush();

			BufferedReader in = new BufferedReader(new InputStreamReader(sock.getInputStream()));
			char buf[] = new char[200];
			int num = 0;
			StringBuffer body = new StringBuffer();
			while ((num=in.read(buf, 0, 200)) >= 0) {
				if (num > 0) {
					body.append(buf, 0, num);
				}
			}
			buf = null;
			out.close();
			in.close();
			sock.close();
			
			System.out.println(logMsg + ": " + body.toString());
			body = null;

		} catch (Exception e) {
			log("Failed in sendRequest: (url=" + urlStr + ") " + e.toString());
			e.printStackTrace();
		}

	}

	/**
	 */
	private void sendRequest1(String urlStr, String logMsg)
		throws Exception
	{

		HttpsURLConnection con = null;
		InputStreamReader reader = null;
		
		try {

			URL url = new URL(urlStr);
			con = (HttpsURLConnection)url.openConnection();
			con.setRequestMethod("GET");

			int responseCode = con.getResponseCode();
			if (responseCode != 200) {
				log("Failed in sendRequest: (" + responseCode + ")"
								+ " " + con.getResponseMessage()
								+ " url = " + urlStr);
				con.disconnect();
				return;
			}

			String ciphers = con.getCipherSuite();
			System.out.println("ciphers = " + ciphers);
			SSLSocketFactory factory = con.getSSLSocketFactory();
			String[] defaultCiphers = factory.getDefaultCipherSuites();
			String tt = "";
			for (int i = 0; i < defaultCiphers.length; ++i) {
				tt += defaultCiphers[i] + ":";
			}
			System.out.println("factory ciphers = " + tt);
			String[] supportedCiphers = factory.getSupportedCipherSuites();
			tt = "";
			for (int i = 0; i < supportedCiphers.length; ++i) {
				tt += supportedCiphers[i] + ":";
			}
			System.out.println("factory supported ciphers = " + tt);

			reader = new InputStreamReader(con.getInputStream());
			char buf[] = new char[200];
			int num = 0;
			StringBuffer body = new StringBuffer();
			while ((num=reader.read(buf, 0, 200)) >= 0) {
				if (num > 0) {
					body.append(buf, 0, num);
				}
			}
			buf = null;

			System.out.println(logMsg + ": " + body.toString());
			body = null;

		} catch (Exception e) {
			log("Failed in sendRequest: (url=" + urlStr + ") " + e.toString());
		} finally {

			if (reader != null)
				reader.close();
			reader = null;

//			if (con != null)
//				con.disconnect();
//			con = null;
		}

	}

}
