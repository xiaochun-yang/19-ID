package sil.dhs;

import java.io.CharArrayWriter;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.text.NumberFormat;
import java.text.ParseException;
import java.util.StringTokenizer;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.factory.InitializingBean;

public class SilDhs extends Thread implements InitializingBean {
	
	private static final int FIXED_LENGTH = 200;
	private static final int HEADER_LENGTH = 26;
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());

	private String beamline;
	private String dcssHost;
	private int dcssPort;
	
	private boolean stopFlag = false;

	public void connect() throws Exception
	{
		Socket sock = null;
		try {
			sock = new Socket(dcssHost, dcssPort);
			// Read timeout in msec
			sock.setSoTimeout(10000);
			
			InputStream in = sock.getInputStream();
			OutputStream out = sock.getOutputStream();
			
			// Read 200 bytes from dcss			
			byte[] buf1 = new byte[200];
			int start = 0;
			int end = 0;
			int numRead = 0;
			while ((numRead=in.read(buf1, start, 200)) > -1) {
				start += numRead;
			}
			
			// Send 200 bytes to dcss
			StringBuffer msg = new StringBuffer();
			msg.append("htos_client_is_hardware sildhs");
			while (msg.length() < 200) {
				msg.append(" ");
			}
			out.write(msg.toString().getBytes());
			
		} catch (Exception e) {
			logger.debug("SilDhs: " + e.getMessage());
//			e.printStackTrace();
		} finally {
			if (sock != null)
				sock.close();
		}
	}
	
	synchronized public boolean getStopFlag() {
		return stopFlag;
	}
	
	synchronized public void setStopFlag(boolean val) {
		stopFlag = val;
	}
	
	private void authenticate() throws Exception {
		// TODO
	}
	
	public void run()
	{
	
		int maxReportedErrors = 5;
		int numReportedErrors = 0;
		
		// Loop in case dcss is restarted
		while (!getStopFlag()) {

		Socket sock = null;
		InputStreamReader in = null;
		OutputStreamWriter out = null;
		InputStream inStream = null;

		// Authenticate webice user here
		// Create a new session id if needed.
		try {
			authenticate();
		} catch (Exception e) {
			logger.error("Cannot connect to beamline " + beamline 
					+ " Root cause: " 
					+ e.getMessage());
			try {
				Thread.sleep(1000); // sleep 1 second before trying again.
			} catch (InterruptedException ee) {
				logger.error("Sleep failed in DcsConnector main loop because " + ee.getMessage());
			}
			
			continue;
		}

		try {

		// #####################################
		// Create socket and io
		// #####################################
		
		// Create a socket with or without SSL
		if (numReportedErrors <= maxReportedErrors)
				logger.info("Use unsecure socket to connect to beamline " + beamline
							+ ": host=" + dcssHost + " port=" + dcssPort);		
		sock = new Socket(dcssHost, dcssPort);
		sock.setSoTimeout(60*1000); // 60 seconds
		
	    out = new OutputStreamWriter(sock.getOutputStream());
		inStream = sock.getInputStream();
	    in = new InputStreamReader(inStream);

		// #####################################
		// Connect to dcss
		// #####################################
		// Wait for stoc_send_client_type message from dcss
		char[] buf1 = readFixedLength(in, FIXED_LENGTH);
		String str = new String(buf1);
		if (!str.startsWith("stoc_send_client_type"))
			throw new Exception("Expected stoc_send_client_type from dcss but got "
						+ str);
		
		System.out.println("==> " + str);
		
		char buf[] = createFixedLengthMessage("htos_client_is_hardware sildhs", FIXED_LENGTH);
		sendMessage(out, buf);

		// #####################################
		// Send and receive dcs messages
		// #####################################
		StringTokenizer tok = null;
		String command = "";
		String device = "";
		int numArgs = 0;
		String curValue = "";
		while (!getStopFlag()) {

			// Read the next message
			// We don't call inStream.available() since
			// it always returns 0 for InputStream from 
			// SSLSocket.
			// Socket read will yield to other threads
			// if there is nothing to read.		
			str = readMessage(in);
			tok = new StringTokenizer(str, " ");
			if (tok.countTokens() < 2)
				continue;
			command = tok.nextToken();
			device = tok.nextToken();
			if (tok.hasMoreTokens()) {
				int pos = str.indexOf(device);
				curValue = str.substring(pos+device.length()+1);
			}
			
			// Register string
			if (command.equals("stoh_register_string")) {
				if (device.equals("sil_id")) {
					String msg = "htos_send_configuration " ;
				} else if (device.equals("sil_event_id")) {
				} else if (device.equals("cassette_list")) {
					
				}
			}
			
		} // while loop
		
		logger.info("sildhs thread for beamline " + beamline + " exiting message loop.");

		} catch (InterruptedException e) {
			++numReportedErrors;
			if (numReportedErrors <= maxReportedErrors)
				logger.debug("sildhs thread " + beamline + ": InterruptedException" + e.getMessage());
		} catch (Exception e) {
			++numReportedErrors;
			if (numReportedErrors <= maxReportedErrors)
				logger.debug("sildhs thread " + beamline + ": Exception " + e.getMessage());
		}

		// #####################################
		// Close socket and io
		// #####################################
		try {
			if (in != null)
				in.close();
		} catch (Exception e) {
			logger.error("Failed to close socket input stream. Root cause: " + e.getMessage());
		}

		try {
			if (out != null)
				out.close();
		} catch (Exception e) {
			logger.error("Failed to close socket output stream. Root cause: " + e.getMessage());
		}

		try {
			if (sock != null)
				sock.close();
		} catch (Exception e) {
			logger.error("Failed to close socket. Root cause: " + e.getMessage());
		}

		in = null;
		inStream = null;
		out = null;
		sock = null;

		if (!getStopFlag()) {
			try {
			// sleep for 1 second before trying to reconnect
			// to dcss again.
			Thread.sleep(1000);
			} catch (InterruptedException e) {
				logger.error("Sleep failed. Root cause: " + e.getMessage());
			}
		}

		} // while loop

		logger.info("silDhs thread for beamline " + beamline + " exited");

	}
	
	// Read dcs message. Expect 26 char for header.
	private String readMessage(InputStreamReader in)
		throws Exception
	{
		if (in == null)
			throw new Exception("readMessage failed: null InputStreamReader");

		char[] header = readFixedLength(in, HEADER_LENGTH);
		int inLen = parseHeader(header);
		char[] inBuf = readFixedLength(in, inLen);

		String str = new String(inBuf).trim();
		System.out.println("<== " + str);

		return str;

	}


	/**
	 * Called only by readMessage().
	 * Read a fixed length message
 	 */
	char[] readFixedLength(InputStreamReader in, int max)
		throws Exception
	{
		if (in == null)
			throw new Exception("readFixedLength failed: null InputStreamReader");

 		char[] arr = new char[max];
		int len = 0;
		int chunk_size = 0;
		while (len < max) {
			chunk_size = in.read(arr, len,  max-len);
			if (chunk_size < 0)
				break;
			len += chunk_size;
		}

		if (len != max)
			throw new Exception("Expected to read " + max + " from socket but got " + len);

		return arr;
	}

	// Parse dcs message header. Expect a number.
	private int parseHeader(char[] header)
		throws Exception
	{
		NumberFormat nf = NumberFormat.getInstance();
		nf.setParseIntegerOnly(true);

		String strHeader = new String(header).trim();
        try {
            return nf.parse(strHeader).intValue();
       	} catch (ParseException e) {
            	throw new Exception("Invalid dcs message header");
        }
	}

	private void sendMessage(OutputStreamWriter out, char buf[])
		throws Exception
	{
		if (out == null)
			throw new Exception("sendMessage failed: null OutputStreamWriter");

		out.write(buf);
		out.flush( );
		
		System.out.println("==> " + new String(buf));
	}

	/**
	 * Create a message of any length. Header is 
	 * always 26 chars.
	 */
	private char[] createMessage(String content)
		throws Exception
	{
		// Construct a dcs message from a string
		String header = Integer.toString(content.length());
		header += " 0";

		int total_length = content.length() + HEADER_LENGTH;
		CharArrayWriter myWriter = new CharArrayWriter(total_length);

		myWriter.write(header, 0, header.length());

		//fill other with 00000
		int pad_length = HEADER_LENGTH - header.length();
		for (int i= 0; i < pad_length; ++i) {
			myWriter.write(0);
		}

		myWriter.write(content, 0,  content.length());
		return myWriter.toCharArray();
		
	}

	private char[] createFixedLengthMessage(String string, int total_length)
	{
		CharArrayWriter myWriter = new CharArrayWriter(total_length);
		myWriter.write( string, 0, string.length() );

		//fill other with 00000
		total_length -= string.length();
		for (int i= 0; i < total_length; ++i) {
			myWriter.write(0);
		}
		return myWriter.toCharArray();
	}
	

	public void afterPropertiesSet() throws Exception {
		if (dcssHost == null)
			throw new Exception("Must set dcssHost property for SilDhs.");
		if (dcssPort <= 0)
			throw new Exception("Must set dcssPort property for SilDhs.");
		
	}

	public String getBeamline() {
		return beamline;
	}

	public void setBeamline(String beamline) {
		this.beamline = beamline;
	}

	public String getDcssHost() {
		return dcssHost;
	}

	public void setDcssHost(String dcssHost) {
		this.dcssHost = dcssHost;
	}

	public int getDcssPort() {
		return dcssPort;
	}

	public void setDcssPort(int dcssPort) {
		this.dcssPort = dcssPort;
	}
}
