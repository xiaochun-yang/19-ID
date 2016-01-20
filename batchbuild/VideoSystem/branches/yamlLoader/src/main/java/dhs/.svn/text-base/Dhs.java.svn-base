package dhs;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.SocketChannel;
import java.nio.channels.spi.SelectorProvider;
import java.nio.charset.Charset;
import java.util.Iterator;
import java.util.Map;
import java.util.Scanner;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class Dhs {

	final static int HEADER_SIZE = 26;
	private String dcssHwHostname;
	private int dcssHwPort;
	private String dhsName;
	private DcsTextMessageParser dcsTextMessageParser;
	
	SocketChannel socket = null;
	Selector socketSelector;

    protected final Log logger = LogFactory.getLog(getClass());	

    
    public void connectToDcss () throws IOException {

    	socketSelector = SelectorProvider.provider().openSelector();

    	InetSocketAddress address = new InetSocketAddress(dcssHwHostname,dcssHwPort);
    	socket = SocketChannel.open();
    	socket.connect(address ); 

    	String message = readNumChar(200); //read out the first message, which is worthless
    	Map<VideoDhsTokenMap, String> map = getDcsTextMessageParser().parseMessage(message.trim());
    	if ( ! map.get(VideoDhsTokenMap.MESSAGE_TYPE).equals("stoc_send_client_type")) {
    		throw new IOException("expected stoc_send_client_type");
    	}

    	StringBuilder msgOut;

    	msgOut = new StringBuilder("htos_client_is_hardware " + dhsName);
    	while (msgOut.length() < 200) {
    		msgOut.append(" ");
    	}
    	Charset charset = Charset.forName("US-ASCII");

    	ByteBuffer msgOutBuf = charset.encode(CharBuffer.wrap(msgOut));
    	msgOutBuf.rewind();
    	socket.write(msgOutBuf);

    	socket.configureBlocking(false);
    	socket.register(socketSelector,SelectionKey.OP_READ);

    }
	
	public void close() {
		try { socket.close(); }
		catch (Exception e) {
		}
	}
	
	public boolean isConnectedToDcss() {
		if (socket == null) return false;
		return socket.isOpen();
	}
	
	public boolean isReadable() throws IOException {
		//socket.register(socketSelector,SelectionKey.OP_READ);
		socketSelector.select(100);

		
        // Iterate over the set of keys for which events are available
        Iterator selectedKeys = socketSelector.selectedKeys().iterator();
        while (selectedKeys.hasNext()) {
          SelectionKey key = (SelectionKey) selectedKeys.next();
          selectedKeys.remove();

          if (!key.isValid()) {
            continue;
          }
          
          // Check what event is available and deal with it
          return key.isReadable();
        }
        return false;
	}
	
	public 	void sendTextMessage(String message) throws IOException {			

		ByteBuffer outMsg = buildTextMessage(message);
		
		while (outMsg.hasRemaining()) {
			socket.write(outMsg);
		}
	}
	
	
	ByteBuffer buildTextMessage(String message) {
		final Charset charset = Charset.forName("US-ASCII");

		ByteBuffer headerBuffer = buildHeader(message);
		ByteBuffer outMsg = ByteBuffer.allocate(headerBuffer.limit() + 1
				+ message.length() );
			
		outMsg.put(headerBuffer);
		outMsg.put(charset.encode(message));
		outMsg.flip();

		return outMsg;
	}
	
	public ByteBuffer buildHeader(String message) {
		Charset charset = Charset.forName("US-ASCII");
		
		StringBuilder header = new StringBuilder(new Integer(message.length()).toString());
		header.append(" 0");		
		
		while (header.length() < HEADER_SIZE) {
			header.append(' ');
		}
		
		ByteBuffer bb_header = charset.encode(header.toString());
		bb_header.put(HEADER_SIZE -1 ,(byte) 0); //terminate the header string
		
		return bb_header;
	}

	public int extractTextSizeFromHeader(String header) {
		Scanner lineScanner = new Scanner(header);
		return lineScanner.nextInt();		
	}

	public String readTextMessage() throws IOException {

		String headerStr=readNumChar(HEADER_SIZE);

		int messageSize = extractTextSizeFromHeader(headerStr);

		String message = readNumChar(messageSize);
		
		return message;
	}

	private String readNumChar(int numChar) throws IOException {
		Charset charset = Charset.forName("US-ASCII");

		ByteBuffer buf = ByteBuffer.allocate(numChar);

		int bytesRead=0;
		while (bytesRead < HEADER_SIZE ) {
			bytesRead += socket.read(buf);
			if (bytesRead == -1) throw new IOException("socket read failed");
		}

		buf.flip();

		return new StringBuffer(charset.decode(buf)).toString();
	}
	
	
	public Map<VideoDhsTokenMap, String> filterTextMessage() throws IOException {
		String message = readTextMessage();
		
		return getDcsTextMessageParser().parseMessage(message);
	}
	
	public String getDcssHwHostname() {
		return dcssHwHostname;
	}


	public void setDcssHwHostname(String dcssHwHostname) {
		this.dcssHwHostname = dcssHwHostname;
	}


	public int getDcssHwPort() {
		return dcssHwPort;
	}


	public void setDcssHwPort(int dcssHwPort) {
		this.dcssHwPort = dcssHwPort;
	}


	public String getDhsName() {
		return dhsName;
	}


	public void setDhsName(String dhsName) {
		this.dhsName = dhsName;
	}

	public DcsTextMessageParser getDcsTextMessageParser() {
		return dcsTextMessageParser;
	}

	public void setDcsTextMessageParser(DcsTextMessageParser dcsTextMessageParser) {
		this.dcsTextMessageParser = dcsTextMessageParser;
	}


	
	
}
