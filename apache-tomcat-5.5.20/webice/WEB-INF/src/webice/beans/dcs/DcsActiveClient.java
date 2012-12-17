package webice.beans.dcs;

import javax.net.ssl.SSLSocketFactory;
import javax.net.SocketFactory;
import java.security.cert.Certificate;
import java.security.*;
import javax.crypto.*;

import java.net.*;
import java.io.*;
import java.util.*;
import java.text.*;
import webice.beans.*;

public class DcsActiveClient
{
	private static final int MAX_WAIT = 1000;
	private static final int FIXED_LENGTH = 200;
	private static final int HEADER_LENGTH = 26;
	private static final int MAX_LOGS = 2000;
	
	private String userName = "";
	private String sessionId = "";
	private String beamline = "";
	private String dcssHost = "";
	private int dcssPort = 0;
	private String display = "webice";
	
	private boolean isStaff = false;
	private boolean isRoaming = false;
	private String location = "unknown";
				
	private char[] inBuf = null;
	private int inLen = 0;
	
	private String systemIdle = "";
	private int numRuns = -1;
	
	private int clientId = -1;
	private int operationCounter = 0;
	
	private LinkedList<String> outQueue = new LinkedList();
	private String waitableOperationHandle = null;
		
	private boolean doDataCollection = false;
	
	private boolean dcssReady = false;
	
	private String collectMsg = "";
		
	private Socket sock = null;
	private InputStreamReader in = null;
	private OutputStreamWriter out = null;
	private InputStream inStream = null;

	/**
	 * constructor
	 */
	public DcsActiveClient(String user, String sessionId, String beamline)
	{
		this.userName = user;
		this.sessionId = sessionId;
		this.beamline = beamline;
		this.dcssHost = ServerConfig.getDcssHost(beamline);
		this.dcssPort = ServerConfig.getDcssPort(beamline);
	}
	
	
	/**
	 * Wait until dcss is ready to receive operations.
	 */
	public void waitForDcss(int timeout)
		throws InterruptedException
	{
		int count = 0;
		int interval = 1000;
		while (!isDcssReady()) {
			Thread.sleep(interval);
			count += interval;
			if (count > timeout*1000.0)
				throw new InterruptedException("waitForDcss timeout after " + timeout + " seconds");	
		}
	}
	
	private boolean isDcssReady()
	{
		return dcssReady;
	}
	
	private void setDcssReady(boolean s)
	{
		dcssReady = s;
	}
		
	/**
	 * Start operation collectWeb to collect 2 test image and autoindex.
	 * Do not wait until operation is completed.
	 */
	public void collectWeb(CollectWebParam param)
		throws Exception
	{
		collectWeb(param, false);	
	}
	
	/**
	 * Start operation collectWeb to collect 2 test image and autoindex
	 */
	public void collectWeb(CollectWebParam param, boolean waitForOperation)
		throws Exception
	{	
		// Make a connection to dcss
		// and wait until dcss is ready
		// to receive messages.
		// Become master.		
		connect(true);
		
		WebiceLogger.info("in collectWeb: num runs = " + getNumRuns() + " max runs = " + DcsConnector.MAX_RUNS);
		if (getNumRuns() >= DcsConnector.MAX_RUNS)
			throw new Exception("Already too many runs");
																
		// Construct collectWeb operation message
		waitableOperationHandle = getUniqueOperationHandle();
		StringBuffer str = new StringBuffer();
		str.append("gtos_start_operation collectWeb");
		str.append(" " + waitableOperationHandle);
		str.append(" " + userName);
		// no longer need to send sessionId
		// dcss will look up in its cache 
		// and replace SID with the real sessionId. 
//		str.append(" PRIVATE" + sessionId);
		str.append(" SID");
		str.append(" " + param.toString());
		
		WebiceLogger.info("DcsActiveClient.collectWeb sending msg: " + str.toString());
				
		outQueue.add(str.toString());
		
		// Send operation to dcss
		// and wait for operation to finish
		// or an error occurs
		startCollectWeb(waitForOperation);
						
	}
	
	/**
	 * abort operation collectWeb to collect 2 test image and autoindex
	 */
	public void abortCollectWeb()
		throws Exception
	{	
		// Make a connection to dcss
		// and wait until dcss is ready
		// to receive messages.
		// Do not become master.
		connect(false);
																		
		// Construct collectWeb operation message
		waitableOperationHandle = getUniqueOperationHandle();
		StringBuffer str = new StringBuffer();
		str.append("gtos_start_operation abortCollectWeb");
		str.append(" " + waitableOperationHandle);
		str.append(" " + userName);
		// no longer need to send sessionId
		// dcss will look up in its cache 
		// and replace SID with the real sessionId. 
//		str.append(" PRIVATE" + sessionId);
		str.append(" SID");
		
		WebiceLogger.info("DcsActiveClient.abortCollectWeb sending msg: " + str.toString());
				
		outQueue.add(str.toString());
		
		// Send operation to dcss
		// and wait for operation to finish
		// or an error occurs
		startAbortCollectWeb();
						
	}
	
	/**
	 * Create a new beamline log
	 */
	public void newUserLog()
		throws Exception
	{	
		// Make a connection to dcss
		// and wait until dcss is ready
		// to receive messages.
		connect(true);
																		
		// Construct collectWeb operation message
		waitableOperationHandle = getUniqueOperationHandle();
		StringBuffer str = new StringBuffer();
		str.append("gtos_start_operation userLog");
		str.append(" " + waitableOperationHandle);
		str.append(" " + userName);
		// no longer need to send sessionId
		// dcss will look up in its cache 
		// and replace SID with the real sessionId. 
//		str.append(" PRIVATE" + sessionId);
		str.append(" SID");
		
		WebiceLogger.info("DcsActiveClient::newUserLog sending msg: " + str.toString());
				
		outQueue.add(str.toString());
		
		// Send operation to dcss
		// and wait for operation to finish
		// or an error occurs
		startUserLogOperation(true);
						
	}

	/**
	 * Use collectWeb operation to create a new run
	 * but without mounting crystal and etc.
	 */
	public void configureRun(RunDefinition run)
		throws Exception
	{
		CollectWebParam param = new CollectWebParam();
		param.def.copy(run);
		
		// Run options
		param.op.mount = false;
		param.op.center = false;
		param.op.autoindex = false;
		param.op.stop = true;

		// wait for operation to finish
		collectWeb(param, true);
		
	}
		/**
	 * Creates a run definition
	 */
	public RunDefinition createRunDefinition()
		throws Exception
	{			
		RunDefinition run = new RunDefinition();
		
		run.deviceName = "";
		run.runStatus = "inactive";
		run.nextFrame = 0;
		run.runLabel = 0;
		run.fileRoot = "myo";
		run.directory = "/data/penjitk/datacollection/myo_try1";
		run.startFrame = 1;
		run.axisMotorName = "gonio_phi";
		run.startAngle = 0.0;
		run.endAngle = 180.0;
		run.delta = 1.0;
		run.wedgeSize = 1.0;
		run.exposureTime = 30.0;
		run.distance = 300.0;
		run.beamStop = 40.0;
		run.attenuation = 0.0;
		run.numEnergy = 1;
		run.energy1 = 12657.972820;
		run.energy2 = 0;
		run.energy3 = 0;
		run.energy4 = 0;
		run.energy5 = 0;
		run.detectorMode = 2;
		run.inverse = 0;
		
		return run;
	}
	
	/**
	 */
	public String getCollectMsg()
	{
		return collectMsg;
	}

						
	/**
	 * Create a unique operation handle
	 */
	private String getUniqueOperationHandle()
	{
		++operationCounter;
		return String.valueOf(clientId) + "." + String.valueOf(operationCounter);
	}
				

	/**
	 * Create a message of any length. Header is 
	 * always 26 chars.
	 */
	private char[] createMessage(String content) 
	{


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


	private char[] getCharArrayWithPad(String string, int total_length) 
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
  		
	
	
	/**
	 * Connect to the dcss and become active if the 
	 * beamline is idle.
	 */
	synchronized private void connect(boolean becomeMaster)
		throws Exception
	{
	
		if ((dcssHost == null) || (dcssHost.length() == 0))
			throw new Exception("Cannot find dcss host name config for beamline " + beamline + " in webice server config");
		if (dcssPort <= 0)
			throw new Exception("Cannot find dcss port config for beamline " + beamline + " in webice server config");
			
		if ((sock != null) && sock.isConnected())
			throw new Exception("Connection to dcss has already been made");
			
		setDcssReady(false);

		// Connect to DCSS via socket
		// Create a socket with or without SSL
		if (ServerConfig.isDcsUseSSL()) {
			WebiceLogger.info("DcsActiveClient connecting with SSL to beamline " + beamline
				+ ": host=" + dcssHost + " port=" + dcssPort);		
			// server certificate must be in the trusted store 
			// specified by -Djavax.net.ssl.trustStore commandline argument.
			SocketFactory socketFactory = SSLSocketFactory.getDefault();
        		sock = socketFactory.createSocket(dcssHost, dcssPort);
		} else {
			WebiceLogger.info("DcsActiveClient connecting to beamline " + beamline
				+ ": host=" + dcssHost + " port=" + dcssPort);		
			sock = new Socket(dcssHost, dcssPort);
		}

	    	out = new OutputStreamWriter(sock.getOutputStream());
		inStream = sock.getInputStream();
	    	in = new InputStreamReader(inStream);
		
		try {
				
		// Wait for stoc_send_client_type message from dcss
		String str = readMessage(in);
		if (!str.startsWith("stoc_send_client_type"))
			throw new Exception("Expected stoc_send_client_type from dcss but got "
						+ str);
		
		// Get unique client id assigned by dcss
		String clientIdStr = "";
		if (str.length() > 21) {
			clientIdStr = str.substring(21).trim();
		}
		
		// If dcss gives us a client id then we
		// need to encrypt the session id as
		// clientId:timestamp:sessionId with 
		// a public key and send it to dcss
		// after gtos_client_is_gui.
		String cipherString = sessionId;
		if (clientIdStr.length() > 0) {
			cipherString = "DCS_CYPHER";
		}
		
		String hostname = ServerConfig.getTomcatHost();		
		if (hostname == null)
			hostname = "unknown";

		// Send "htos_client_is_gui userName sessionId hostname display"
		str = "gtos_client_is_gui " + userName 
				+ " " + cipherString
				+ " " + hostname
				+ " " + display;
		char[] buf = getCharArrayWithPad(str, FIXED_LENGTH);
		sendConnectionMessage(out, buf, false); // do not log this message since it contains '\0' chars
		
		// If we only send DCS_CIPHER in gtos_client_is_gui
		// then here we need to send the encrypted 
		// clientId:timestamp:sessionId as a dcss message.
		if (cipherString.equals("DCS_CYPHER")) {
			// Time since January 1, 1970, 00:00:00 GMT in seconds
			long timestamp = new Date().getTime()/1000;
			String rawTxt = clientIdStr + ":" + timestamp + ":" + sessionId;
			// Keystore password
			String password = ServerConfig.getDcsKeystorePassword();
			String keystoreName = ServerConfig.getDcsKeystoreFile();
			// The certificate is saved in the keystore with beamline name
			// as the certificate entry name 
			String alias = beamline;
			// Encrypt the string with public key
			// and encode the bytes with base64 encoding.
			String encryptedTxt = DcsConnector.encrypt(keystoreName, password, alias, rawTxt);
			sendMessage(encryptedTxt);
		}

		// Wait for stog_respond_to_challenge from dcss
		str = readMessage(in);
		if (str.indexOf("stog_login_complete") == 0) {
			WebiceLogger.info("Got stog_login_complete: " + str);
			try {
				clientId = Integer.parseInt(str.substring(20).trim());
				WebiceLogger.info("clientId = " + clientId);
			} catch (NumberFormatException e) {
				throw new Exception("Failed to get client id from stog_login_complete: " + str);
			}
		} else {
			throw new Exception("Expected stog_login_complete from dcss but got " + str);
		}
					
		// Wait until DCSS is ready
		StringTokenizer tok = null;
		String command = "";
		String device = "";
		int numArgs = 0;
		boolean isMaster = false;
		boolean sent = false;
		String owner = "";
				
		// If we want to become master then loop until we become master
		// If wa don't want to become master then only loop until dcss has sent out all messages
		while ((becomeMaster && !isMaster) || (!becomeMaster && !isDcssReady())) {
					
			// Read the next message
			// We don't call inStream.available() since
			// it always returns 0 for InputStream from 
			// SSLSocket.
			// Socket read will yield to other threads
			// if there is nothing to read.
			str = readMessage(in);
						
			// Don't parse log messages
			// Save it in a list
			if (str.startsWith("stog_log")) {
				continue;
			}
			
			tok = new StringTokenizer(str, " ");
			numArgs = tok.countTokens();
			command = tok.nextToken();
			device = "";
			if (numArgs > 1)
				device = tok.nextToken();
				
			// Get system_idle string
			if (command.equals("stog_configure_string") || command.equals("stog_set_string_completed")) {
				if (device.equals("system_idle")) {
					if (numArgs <= 3) {
						systemIdle = "";
					} else {
						owner = tok.nextToken();
						systemIdle = tok.nextToken();
					}
				} else if (device.equals("runs")) {
					if (numArgs >= 4) {
					tok.nextToken(); // third arg not used
					String tt = tok.nextToken(); // 4th arg
					try {
						int n = Integer.parseInt(tt);
						setNumRuns(n);
					} catch (NumberFormatException e) {
						throw new Exception("Failed to parse stog_configure_runs: " + str);
					}
					}
				}
			} else if (command.equals("stog_become_master")) {
				isMaster = true;
			} else if (command.equals("stog_dcss_end_update_all_device")) {
				// We can start sending messages to dcss
				// after this.
				setDcssReady(true);
				WebiceLogger.info("DCSS is now ready to receive messages from gui");
				
				// Now try to become master
				if (becomeMaster && !sent) {
					if (systemIdle.length() > 0)
						throw new Exception("Cannot become master since system_idle string is not empty: " + systemIdle);
					sendMessage("gtos_become_master force");
					sent = true;
				}
			}
			
		}
		
		} catch (Exception e) {
			in.close();
			out.close();
			sock.close();
		
			in = null;
			inStream = null;
			out = null;
			sock = null;
			
			throw e;
		}
		
		WebiceLogger.info("DcsActiveClient: connect exit");
		
	}
	
	
	/**
	 */
	private void startAbortCollectWeb()
		throws Exception
	{
		startCollectWeb(true);
	}

	/**
	 */
	private void startCollectWeb(boolean waitForOperation)
		throws Exception
	{	
		if ((sock == null) || !sock.isConnected())
			throw new Exception("DCSS socket is null or is not connected");

		if (!isDcssReady())
			throw new Exception("DCSS is not ready to receive a message from gui client");
			
		try {
		
		StringTokenizer tok = null;
		String command = "";
		String device = "";
		int numArgs = 0;
		String str = null;
		String owner = "";
		while (waitableOperationHandle != null) {
		
			if (outQueue.size() > 0)
				sendMessages(out);
		
			// Read the next message
			// We don't call inStream.available() since
			// it always returns 0 for InputStream from 
			// SSLSocket.
			// Socket read will yield to other threads
			// if there is nothing to read.
			str = readMessage(in);
						
			// Don't parse log messages
			if (str.startsWith("stog_log"))
				continue;
			
			tok = new StringTokenizer(str, " ");
			numArgs = tok.countTokens();
			command = tok.nextToken();
			device = "";
			if (numArgs > 1)
				device = tok.nextToken();
				
			if (command.equals("stog_configure_string") || command.equals("stog_set_string_completed")) {
				if (device.equals("system_idle")) {
					if (numArgs <= 3) {
						systemIdle = "";
					} else {
						owner = tok.nextToken();
						systemIdle = tok.nextToken();
					}
				} else if (device.equals("collect_msg")) {
					collectMsg = str;
				}
			} else if (command.equals("stog_start_operation")) {
				if (device.equals("collectWeb")) {
					// Stop waiting after it has started
					String handle = tok.nextToken();
					if ((waitableOperationHandle != null) && waitableOperationHandle.equals(handle)) {
						WebiceLogger.info("Got stog_operation_start: " + str);
						if (!waitForOperation)
							waitableOperationHandle = null;
					}
				}
			} else if (command.equals("stog_operation_completed") && (device.indexOf("ollectWeb") > -1)) {
				String handle = tok.nextToken();
				if ((waitableOperationHandle != null) && waitableOperationHandle.equals(handle)) {
					WebiceLogger.info("Got stog_operation_completed: " + str);
					waitableOperationHandle = null;
					String status = tok.nextToken();
					if (status.indexOf("normal") < 0)
						throw new Exception(device + " operation failed: " + str);
				}
			}
		}
		
		} catch (Exception e) {
			throw e;
		} finally {
		
			in.close();
			out.close();
			sock.close();
		
			in = null;
			inStream = null;
			out = null;
			sock = null;
		
			WebiceLogger.info("DcsActiveClient finished collectWeb for " + beamline);
		}
		

	}
	
	/**
	 */
	private void startUserLogOperation(boolean waitForOperation)
		throws Exception
	{
	
		if ((sock == null) || !sock.isConnected())
			throw new Exception("DCSS socket is null or is not connected");

		if (!isDcssReady())
			throw new Exception("DCSS is not ready to receive a message from gui client");
			
		try {
		
		StringTokenizer tok = null;
		String command = "";
		String device = "";
		int numArgs = 0;
		String str = null;
		String owner = "";
		while (waitableOperationHandle != null) {
		
			if (outQueue.size() > 0)
				sendMessages(out);
					
			// Read the next message
			// We don't call inStream.available() since
			// it always returns 0 for InputStream from 
			// SSLSocket.
			// Socket read will yield to other threads
			// if there is nothing to read.
			str = readMessage(in);
						
			// Don't parse log messages
			if (str.startsWith("stog_log"))
				continue;
			
			tok = new StringTokenizer(str, " ");
			numArgs = tok.countTokens();
			command = tok.nextToken();
			device = "";
			if (numArgs > 1)
				device = tok.nextToken();
				
			if (command.equals("stog_configure_string") || command.equals("stog_set_string_completed")) {
				if (device.equals("system_idle")) {
					if (numArgs <= 3) {
						systemIdle = "";
					} else {
						owner = tok.nextToken();
						systemIdle = tok.nextToken();
					}
				} else if (device.equals("collect_msg")) {
					collectMsg = str;
				}
			} else if (command.equals("stog_start_operation")) {
				if (device.equals("userLog")) {
					// Stop waiting after it has started
					String handle = tok.nextToken();
					if ((waitableOperationHandle != null) && waitableOperationHandle.equals(handle)) {
						WebiceLogger.info("Got stog_operation_start: " + str);
						if (!waitForOperation)
							waitableOperationHandle = null;
					}
				}
			} else if (command.equals("stog_operation_completed") && (device.indexOf("userLog") > -1)) {
				String handle = tok.nextToken();
				if ((waitableOperationHandle != null) && waitableOperationHandle.equals(handle)) {
					WebiceLogger.info("Got stog_operation_completed: " + str);
					waitableOperationHandle = null;
					String status = tok.nextToken();
					if (status.indexOf("normal") < 0)
						throw new Exception(device + " operation failed: " + str);
				}
			}
		}
		
		} catch (Exception e) {
			throw e;
		} finally {
		
			in.close();
			out.close();
			sock.close();
		
			in = null;
			inStream = null;
			out = null;
			sock = null;
		
			WebiceLogger.info("DcsActiveClient finished userLog for " + beamline);
		}
		

	}
	
	/**
	 * Called only by run().
	 * Read dcs message. Expect 26 char for header.
	 */
	private String readMessage(InputStreamReader in)
		throws Exception
	{
		if (in == null)
			throw new Exception("readMessage failed: null InputStreamReader");

		char[] header = readFixedLength(in, HEADER_LENGTH);
		inLen = parseHeader(header);
		inBuf = readFixedLength(in, inLen);
		
		String str = new String(inBuf).trim();
		if (!str.contains("hutchDoorStatus") && !str.contains("update_motor_position") && !str.contains("robot_attribute"))
			WebiceLogger.info("DcsActiveClient <== " + str);
		
		return str;
				
	}
	
	/**
	 * Called only by run().
	 * Send messages in the queue
	 */
	private void sendMessages(OutputStreamWriter out)
		throws Exception
	{
		if (outQueue.size() == 0)
			return;
			
		String content = null;
		char buf[] = null;
		while (outQueue.size() > 0) {
			content = outQueue.removeFirst();
			// Create a dcs message for this string
			buf = createMessage(content);
			// Send the message
			out.write(buf);
			out.flush();
			buf = null;
			WebiceLogger.info("==> " + content);
		}
	}
	
	private void sendMessage(String content)
		throws Exception
	{
		char buf[] = null;
		// Create a dcs message for this string
		buf = createMessage(content);
		// Send the message
		out.write(buf);
		out.flush();
		buf = null;
		WebiceLogger.info("==> " + content);
	}

	/**
	 * Called only by readMessage().
	 * Read a fixed length message
 	 */
	private char[] readFixedLength(InputStreamReader in, int max)
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

	/**
	 * Called by readMessage().
	 * Parse dcs message header. Expect a number.
	 */
	private int parseHeader( char[] header ) 
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

	/**
	 * Called only by run().
	 * Send a dcs message.
	 */
	private void sendConnectionMessage(OutputStreamWriter out, char buf[])
		throws Exception
	{
		sendConnectionMessage(out, buf, true);
	}
	
	/**
	 * Called only by run().
	 * Send a dcs message.
	 */
	private void sendConnectionMessage(OutputStreamWriter out, char buf[], boolean isLogging)
		throws Exception
	{
		if (out == null)
			throw new Exception("sendMessage failed: null OutputStreamWriter");

		out.write(buf);
		out.flush( );
		if (isLogging)
			WebiceLogger.info("==> " + new String(buf));
	}

	// Called by AutoindexViewer to find out 
	// if we have received stog_config_runs from dcss.
	public int getNumRuns()
	{
		return numRuns;
	}	

	/**
	 * Called by run()
	 */
	private void setNumRuns(int n)
	{
		numRuns = n;
	}
	
	
}


