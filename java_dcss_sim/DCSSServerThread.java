//import javax.swing.*;
//import javax.swing.text.*;

import java.awt.*;              //for layout managers
import java.awt.event.*;        //for action and window events
import java.net.*;
import java.io.*;

public class DCSSServerThread extends Thread {
    private Socket socket = null;
    private static int counter = 0;

    //change it to true if you want the program to wait reply
    //change it to faulse if you do NOT want the program to wait reply
    //before sending out next message
    private static boolean WAIT_REPLY = true;

    private DCSSWindow frame = new DCSSWindow();


    public DCSSServerThread(Socket socket) {
	super(Integer.toString(++counter));
	this.socket = socket;
        frame.pack();
        frame.setVisible(true);
    }

    public void run() {
        //System.out.println("run thread");

	try {
	    OutputStreamWriter out = new OutputStreamWriter(socket.getOutputStream());
	    InputStreamReader in = new InputStreamReader( socket.getInputStream());

	    DCSProtocol kkp = new DCSProtocol();
            kkp.setLog( frame.getTextArea() );

            DCSMessage msg = new DCSMessage();
	    kkp.processInput(msg);


	    while (true) {

                if (msg.OutBuf == null && msg.InLen == 0) {
                    //System.out.println("both OutBuf and InLen are 0, exit");
                    frame.getTextArea( ).append( "NO ACTION, QUIT " );
                    break;
                }

                if (msg.OutBuf != null) {
                    //System.out.print("==>");
                    //System.out.println(msg.OutBuf);
                    out.write(msg.OutBuf);
                    out.flush( );
                    msg.OutBuf = null;
                }

                //check to see if we need to read socket
                boolean need_read = false;
                if (WAIT_REPLY) {
                    if (msg.InLen > 0) {
                        need_read = true;
                    }
                } else {
                    if (msg.InLen > 0) {
                        try {
                            int avail_length = socket.getInputStream().available();
                            if (avail_length >= msg.InLen) {
                                //System.out.print("available=");
                                //System.out.println(avail_length);
                                need_read = true;
                            }
                        }
                        catch (IOException e)
                        {
							System.out.println(e.getMessage());
                        }
                    }
                }
                if (need_read) {
                    //System.out.println("need read");
                    msg.InBuf = new char[msg.InLen];
                    int readlen = in.read( msg.InBuf, 0,  msg.InLen );

                    //if (readlen > 0) {
                    //    System.out.print(readlen);
                    //    System.out.print("<==");
                    //    System.out.println(msg.InBuf);
                    //}
                    if (readlen != msg.InLen) {
                        //System.out.println("read lenght bad");
                        //System.out.print("readlen=");
                        //System.out.println(readlen);
                        //System.out.print("supposed InLen=");
                        //System.out.print(msg.InLen);
                        frame.getTextArea( ).append( "reading error " );
                        break;
                    }
                }
                kkp.processInput(msg);

 	    }
            in.close();
            out.close();
            socket.close();

        } catch (IOException e) {
            e.printStackTrace();
        }
        frame.getTextArea( ).append( "SOCKET CLOSED\n" );
        frame.getTextArea( ).setCaretPosition(frame.getTextArea( ).getText().length());

    }
}
