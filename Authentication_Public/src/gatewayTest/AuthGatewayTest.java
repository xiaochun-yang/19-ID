import java.io.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.util.*;
import edu.stanford.slac.ssrl.authentication.utility.*;

public class AuthGatewayTest extends JFrame implements ActionListener {
	
	private JTextArea textArea = null;
	private JTextField tHost = null;
	private JTextField tUser = null;
	private JPasswordField tPwd = null;
	private JButton cmdLogin = null;
	private JButton cmdRefresh = null;
	private JButton cmdLogout = null;
	private JButton cmdWeb = null;
	
	private AuthGatewayBean authBean = null;
	private String smbSessionID = null;
    
    /*** The constructor.
     */  
     public AuthGatewayTest() {
                
        setTitle("GatewayTest");
        JPanel topPanel = new JPanel();
        topPanel.setLayout(new BorderLayout());
        getContentPane().add(topPanel);
        
        textArea = new JTextArea();
        textArea.setSize(374, 205);
        textArea.setEditable(false);
        JScrollPane sPane = new JScrollPane(textArea);
        topPanel.add(sPane, BorderLayout.CENTER);
        
        JPanel midPanel = new JPanel();
        midPanel.setLayout(new FlowLayout());
        JLabel lHost = new JLabel("Host:");
        lHost.setVisible(true);
        lHost.setText("Host:");
        tHost = new JTextField("http://localhost", 10);
        JLabel lUser = new JLabel("Userid:");
        tUser = new JTextField("",10);
        JLabel lPwd = new JLabel("Passwd:");
        tPwd = new JPasswordField("", 10);
        midPanel.add(lHost);
        midPanel.add(tHost);
        midPanel.add(lUser);
        midPanel.add(tUser);
        midPanel.add(lPwd);
        midPanel.add(tPwd);
        topPanel.add(midPanel, BorderLayout.NORTH);
        
        JPanel bottomPanel = new JPanel();
        bottomPanel.setLayout(new FlowLayout());
        cmdLogin = new JButton("Login");
        cmdRefresh = new JButton("Refresh");
        cmdRefresh.setEnabled(false);
        cmdLogout = new JButton("Logout");
        cmdLogout.setEnabled(false);
        cmdWeb = new JButton("Web");
        cmdWeb.setEnabled(false);
        bottomPanel.add(cmdLogin);
        bottomPanel.add(cmdRefresh);
        bottomPanel.add(cmdLogout);
        bottomPanel.add(cmdWeb);
        topPanel.add(bottomPanel, BorderLayout.SOUTH);
        
        cmdLogin.addActionListener(this);
        cmdRefresh.addActionListener(this);
        cmdLogout.addActionListener(this);
        cmdWeb.addActionListener(this);
        
        
        setSize(new Dimension(525, 300));
        
        // Add window listener.
        this.addWindowListener
        (
            new WindowAdapter() {
                public void windowClosing(WindowEvent e) {
                    AuthGatewayTest.this.windowClosed();
                }
            }
        );  
    }
    
    public void actionPerformed(ActionEvent event) {
    	if (event.getSource() == cmdLogin) {
    		cmdLogin();
    	} else if (event.getSource() == cmdLogout) {
    		cmdLogout();
    	} else if (event.getSource() == cmdRefresh) {
    		cmdRefresh();
    	} else if (event.getSource() == cmdWeb) {
    		cmdWeb();
    	}
    }
    
    /**
     * Shutdown procedure when run as an application.
     */
    protected void windowClosed() {
    	
    	doLogout();
        // Exit application.
        System.exit(0);
    }
    
        public static void main(String[] args) {
    	
        // Create application frame.
        AuthGatewayTest frame = new AuthGatewayTest();
        
        // Show frame.
        frame.show();
    }

	private void UpdateText() {
        String textOut = "";
        if (authBean != null) {
        	textOut = "Session created with AuthGatewayBean.";
        	textOut = textOut.concat("\nSession ID: " + smbSessionID);
        	textOut = textOut.concat("\nSession Valid: " + authBean.isSessionValid());                
        	try {
            	Date createDate = new Date(Long.parseLong(authBean.getCreationTime()));
            	textOut = textOut.concat("\nCreated: " + createDate.toString());                     
            	Date accessDate = new Date(Long.parseLong(authBean.getLastAccessTime()));
            	textOut = textOut.concat("\nAccessed: " + accessDate.toString());
        	} catch (NumberFormatException e) {}
        	textOut = textOut.concat("\nLogin: " + authBean.getUserID());
        	textOut = textOut.concat("\nAuthGatewayBean properties: ");
        	Hashtable tstProps = authBean.getProperties();
        	if (tstProps != null) {
        		for (Enumeration e1 = tstProps.keys(); e1.hasMoreElements();) {
        			Object key = e1.nextElement();
        			String paramVal = (String) tstProps.get(key);
        			String paramName = (String) key;
        			textOut = textOut.concat("\n" + paramName + ": " + paramVal);
        		}
        	}
        }
        textArea.setText(textOut);
	}

	private void cmdLogin()
	{
	    // here's how we log somebody in
	   
        boolean authenticated = false;
        authBean = null;
 
        String appName = "SMBTest";
        String authMethod = "simple_user_database";
        authBean = new AuthGatewayBean();
        authBean.initialize(appName, tUser.getText(), tPwd.getText(), authMethod, tHost.getText());
        authenticated = authBean.isSessionValid();
        smbSessionID = authBean.getSessionID();
            
        if (authenticated) {
            UpdateText();
            
            // set our controls, and we're done
            cmdLogin.setEnabled(false);
            cmdRefresh.setEnabled(true);
            cmdLogout.setEnabled(true);
            cmdWeb.setEnabled(true);
		} else {
		    textArea.setText("Unable to authenticate user.");
			smbSessionID = null;
        }
	}

	void cmdRefresh()
	{
	    // refresh the session info display
        boolean validSession = false;
        if (smbSessionID != null && authBean != null) {
        	String appName = "SMBTest";
       		validSession = authBean.isSessionValid();
        }
        if (validSession) {
        	authBean.updateSessionData(true);
            UpdateText();
        } else {
            textArea.setText("Requested session is not valid.");
            cmdLogin.setEnabled(true);
            cmdRefresh.setEnabled(false);
            cmdLogout.setEnabled(false);
            cmdWeb.setEnabled(false);
            smbSessionID = null;
        }
	}
	
	private void doLogout() {
	    // logout the user by calling the logout servlet
	    // this routine is called by the logout button and when the application ends
	    if (authBean != null) {
	    	authBean.endSession();
	    	authBean = null;
	    }
	    smbSessionID = null;
	}

	void cmdLogout()
	{
		doLogout();
		textArea.setText("User has been logged out.");
		cmdLogin.setEnabled(true);
		cmdRefresh.setEnabled(false);
		cmdLogout.setEnabled(false);
		cmdWeb.setEnabled(false);
			 
	}
	
	void cmdWeb()
	{
	    // open a browser with SMBTest
	    String authHost = tHost.getText();
        if (authHost != null && smbSessionID != null)  try {
        	String htmlFile = buildTempHtml(authHost, "http://smbdev1.slac.stanford.edu/examples/servlet/SimpleAuth_Test1");
        	String osname = System.getProperty("os.name");
        	if (osname.indexOf("Windows") > -1) {
        		Runtime.getRuntime().exec("explorer file://" + htmlFile);
        	} else if (osname.indexOf("Linux") > -1) {
        		Runtime.getRuntime().exec("htmlview file://" + htmlFile);
        	} else {
        		Runtime.getRuntime().exec("netscape file://" + htmlFile);
        	}
	    } catch (IOException e) {
	    	System.out.println("io exception trying to open web browser.");
	    }
	}
	
	String buildTempHtml(String authHost, String url) {
	    // build a temporary html file which will, onload, go the the requested 
	    // application. For some reason, this works better on unix than trying to
	    // pass the actual url directly to netscape
	    String filePath = null;
	    try {
	        File myFile = File.createTempFile("SMBAuth", ".html");
	        myFile.deleteOnExit();
	        filePath = myFile.getPath();
	        PrintWriter pw = new PrintWriter(new FileWriter(myFile), true);
            pw.println("<HTML><HEAD><TITLE>APPFORWARD Test</TITLE>");
            pw.println("<SCRIPT Language=JavaScript>");
            pw.println( "    function buttonClicked()");
            pw.println("    {");
            pw.println("        document.formSubmit.submit();");
            pw.println("    }");
            pw.println("</script>");
            pw.println("</HEAD>");
            pw.println("<BODY onload=buttonClicked()>");
            pw.println("<P>");
            pw.println("<form name=formSubmit action=\"" + authHost + "/gateway/servlet/APPFORWARD\" method=POST>");
            pw.println("<B>If you are not automatically taken to the requested page within a few seconds, click the button below:</B><BR>");
            pw.println("<input type=\"hidden\" name=\"URL\" value=\"" + url + "\" >");
            pw.println("<input type=\"hidden\" name=\"AppSessionID\" value=\"" + smbSessionID + "\" >");
            pw.println("<input type=\"hidden\" name=\"AppName\" value=\"SMBTest\" >");
            pw.println("<input type=\"button\" value=\"Submit\" onClick=buttonClicked()>");
            pw.println("</form></P>");
            pw.println("</body></HTML>");
	        pw.close();
	    } catch (IOException e) {System.out.println("unable to create temp file");
	    }	    
	    return filePath;
	}

}
