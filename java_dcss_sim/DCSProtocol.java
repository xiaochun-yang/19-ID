import javax.swing.*;
import javax.swing.text.*;

import java.net.*;
import java.io.*;
import java.util.*;
import java.text.*;

public class DCSProtocol {
    private static final int SENDING_CLIENT_TYPE = 0;
    private static final int WAIT_CLIENT_TYPE = 1;
    private static final int WAIT_HEADER = 2;
    private static final int WAIT_MESSAGE = 3;

    private static final int FIXED_LENGTH = 200;
    private static final int HEADER_LENGTH = 26;

    private int state = SENDING_CLIENT_TYPE;

    private int counter = 0;

    private JTextArea m_log = null;

    private static List myCommands = new LinkedList();

    private ListIterator myIterator = myCommands.listIterator();

    public static void loadCommand( String fileName ) throws FileNotFoundException, IOException {
        if (myCommands.size() > 0) return;

        FileReader myFile = new FileReader(fileName);
        BufferedReader in = new BufferedReader( myFile );
        String oneLine;

        while ((oneLine = in.readLine()) != null) {
            //System.out.println(oneLine);
            myCommands.add(oneLine);
        }
    }

    public void setLog( JTextArea log ) {
        m_log = log;
    }
    public void processInput( DCSMessage msg ) {

        //System.out.println("processInput");

        //check to see if we are running in "not-wait-for-reply" mode
        if ((state != SENDING_CLIENT_TYPE ) && (msg.InBuf == null)) {
            try {
                Thread.sleep(1000);
            }
            catch (InterruptedException e) {
            }
            if (state >= WAIT_HEADER) {
                //System.out.println("sending without waint");
                msg.OutBuf = createMessage( getOperation() );
            }
            //do not change state
            return;
        }

        switch (state)
        {
            case SENDING_CLIENT_TYPE:
                //System.out.println("state = SENDING_CLIENT_TYPE");
                String myMsg = "stoc_send_client_type";
                String log_msg = "==>";
                log_msg += myMsg;
                System.out.println( log_msg );
                if (m_log != null) {
                    m_log.append( log_msg +"\n" );
                }

                msg.OutBuf = getCharArrayWithPad( myMsg, FIXED_LENGTH );
                msg.InLen = FIXED_LENGTH;
                state = WAIT_CLIENT_TYPE;
                break;

            case WAIT_CLIENT_TYPE:
                //System.out.print( "received: " );
                //System.out.println( msg.InBuf );
                //System.out.print( "len=");
                //System.out.println( msg.InBuf.length );
                log_msg = "<==";
                log_msg += new String( msg.InBuf );
                System.out.println( log_msg );
                if (m_log != null) {
                    m_log.append( log_msg +"\n" );
                }

                msg.OutBuf = createMessage( getOperation() );
                msg.InLen = HEADER_LENGTH;
                state = WAIT_HEADER;
                break;

            case WAIT_HEADER:
                //System.out.print( "got header " );
                //System.out.println( msg.InBuf );

                msg.OutBuf = null; //nothing to send
                msg.InLen = parseHeader( msg.InBuf );
                state = WAIT_MESSAGE;
                break;

            case WAIT_MESSAGE:
                String strReply = new String(msg.InBuf);

                log_msg = "<==";
                log_msg += strReply;
                System.out.println( log_msg );
                if (m_log != null) {
                    m_log.append( log_msg +"\n" );
                    m_log.setCaretPosition(m_log.getText().length());
                }

                if (strReply.startsWith("htos_operation_completed")) {
                    msg.OutBuf = createMessage( getOperation() );
                } else {
                    msg.OutBuf = null;
                }
                msg.InLen = HEADER_LENGTH;
                state = WAIT_HEADER;
        }

        //System.out.println("AT the end of processInput");
        //if (msg.OutBuf != null) {
        //    System.out.print( "out=" );
        //    System.out.println( msg.OutBuf );
        //}
        //System.out.print( "InLen=" );
        //System.out.println( msg.InLen );
        msg.InBuf = null;
    }

    private String getOperation( ) {
        String operation = null;
        try {
            operation = (String)myIterator.next();
        }
        catch (NoSuchElementException e)
        {
            myIterator = myCommands.listIterator( );
            operation = (String)myIterator.next();
        }
        //System.out.print( "getOperation :" );
        //System.out.println( operation );
        return operation;
    }

    private char[] getCharArrayWithPad( String string, int total_length ) {
        CharArrayWriter myWriter = new CharArrayWriter(total_length);
        myWriter.write( string, 0, string.length() );

        //fill other with 00000
        total_length -= string.length();
        for (int i= 0; i < total_length; ++i) {
            myWriter.write(0);
        }
        return myWriter.toCharArray();
    }

    private char[] createMessage( String operation ) {

        String msg = "stoh_start_operation ";

		// find the first space char
		int pos = operation.indexOf(' ');
		if (pos < 0) {
			msg += operation.trim();
		} else {
			msg += operation.substring(0, pos);

		}

        msg += " ";
        msg += Thread.currentThread().getName();
        msg += ".";
        msg += counter++;
        if (pos < 0) {
			msg += " arguments";
		} else {
			msg += operation.substring(pos);
		}

        String log_msg = "==>";
        log_msg += msg;
        System.out.println( log_msg );
        if (m_log != null) {
            m_log.append( log_msg +"\n" );
            m_log.setCaretPosition(m_log.getText().length());
        }


        String header = Integer.toString(msg.length( ));
        header += " 0";

        int total_length = msg.length() + HEADER_LENGTH;
        CharArrayWriter myWriter = new CharArrayWriter(total_length);

        myWriter.write( header, 0, header.length() );

        //fill other with 00000
        int pad_length = HEADER_LENGTH - header.length( );
        for (int i= 0; i < pad_length; ++i) {
            myWriter.write(0);
        }

        myWriter.write( msg, 0,  msg.length( ));
        return myWriter.toCharArray();
    }

    private int parseHeader( char[] header ) {
        NumberFormat nf = NumberFormat.getInstance();
        nf.setParseIntegerOnly(true);

        String strHeader = new String(header);

        strHeader = strHeader.trim( );

        int result = 0;

        try {
            result = nf.parse(strHeader).intValue();
        }
        catch (ParseException e)
        {
            result = 0;
        }
        return result;
    }
}
