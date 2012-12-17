/* httpupload.java
*
*
*/

package httpupload3;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.net.*;
import java.io.*;
//
class httpupload extends Frame implements ActionListener, WindowListener
{
String m_demoFile= "test3.xls";
String m_serverURL= "http://gwolfpc/excel2xml/excel2xml.asp";
String m_user= "jcsg";
//
TextField c_file;
TextField c_server;
TextField c_user;
TextField c_passw;
Button b_browse;
Button b_run;
TextField c_info;
		 
//--------------------------

httpupload()
{
super( "httpupload");

Panel p1= new Panel();
Label l;

c_file= new TextField( m_demoFile, 34);
c_server= new TextField( m_serverURL, 20);
c_user= new TextField( m_user, 20);;
c_passw= new TextField("", 20);;
b_browse= new Button("...");
b_run= new Button("Run");
c_info= new TextField("", 37);

c_passw.setEchoChar('*');
c_info.setEditable(false); 

setBackground( Color.lightGray);
p1.setBackground( Color.lightGray);
c_info.setBackground( Color.lightGray);

GridBagLayout g= new GridBagLayout();
GridBagConstraints gbc= new GridBagConstraints();
p1.setLayout(g);
//gbc.fill= GridBagConstraints.BOTH;
gbc.weightx= 0.0;// normal width
gbc.weighty= 0.0;// normal heigt
gbc.gridwidth= 1;
gbc.gridheight=1;
gbc.insets.left= 4;
gbc.insets.right= 4;
gbc.insets.top= 4;
gbc.insets.bottom= 4;
gbc.anchor= GridBagConstraints.WEST; 

//HeaderLabel
gbc.gridy= 0;
gbc.gridx= 0;
gbc.gridwidth= 4;
l= new Label( "File for upload to Web server:");
g.setConstraints( l, gbc);
p1.add( l);
gbc.gridwidth= 1;

//file
gbc.gridy= 1;
gbc.gridx= 0;
//l= new Label( "File:" );
//g.setConstraints( l, gbc);
//p1.add( l);

//gbc.gridx= 1;
gbc.gridwidth= 2;
g.setConstraints( c_file, gbc);
p1.add( c_file);
gbc.gridwidth= 1;

//browse
gbc.gridx= 2;
gbc.insets.left= 0;
g.setConstraints( b_browse, gbc);
p1.add( b_browse);
gbc.insets.left= 4;

//server
gbc.gridy= 2;
gbc.gridx= 0;
l= new Label( "Server URL:" );
g.setConstraints( l, gbc);
p1.add( l);
	
gbc.gridx= 1;
g.setConstraints( c_server, gbc);
p1.add( c_server);

//user
gbc.gridy= 3;
gbc.gridx= 0;
l= new Label( "User Name:" );
g.setConstraints( l, gbc);
p1.add( l);
	
gbc.gridx= 1;
g.setConstraints( c_user, gbc);
p1.add( c_user);

//password
gbc.gridy= 4;
gbc.gridx= 0;
l= new Label( "Password:" );
g.setConstraints( l, gbc);
p1.add( l);
	
gbc.gridx= 1;
g.setConstraints( c_passw, gbc);
p1.add( c_passw);

//run
gbc.gridy= 5;
gbc.gridx= 1;
g.setConstraints( b_run, gbc);
p1.add( b_run);

//info
gbc.gridy= 6;
gbc.gridx= 0;
gbc.gridwidth= 4;
g.setConstraints( c_info, gbc);
p1.add( c_info);
gbc.gridwidth= 1;


//add(p1);
setLayout(new BorderLayout());
add(p1, BorderLayout.CENTER);
pack();

//
addWindowListener(this);
b_browse.addActionListener( this);
b_run.addActionListener( this);
}

//--------------------------
// ActionListener

public void actionPerformed( ActionEvent evt)
{
String command= evt.getActionCommand();
out( command);
if( evt.getSource()==b_browse)
{
	FileDialog fd= new FileDialog( this, "Select File", FileDialog.LOAD);
	fd.show();
	String fname= "";
	if( fd.getDirectory()!=null && fd.getFile()!=null)
	{
		fname= fd.getDirectory()+fd.getFile();
		c_file.setText(fname);
	}
	out("fname="+ fname);
}
else
if( evt.getSource()==b_run)
{
	
	String accessID= null;
	b_run.setEnabled( false);
	setCursor( Cursor.getPredefinedCursor( Cursor.WAIT_CURSOR));
	c_info.setText( "Login...");
	String result= "";
	result= login();
	out( "Login: "+ result);
	c_info.setText( "Login: "+ result);
	if( result.startsWith("Err")==true )
	{
		b_run.setEnabled( true);
		setCursor( Cursor.getDefaultCursor());
		return;
	}
	accessID= result;
	c_info.setText( "Read data...");
	
	String fname= c_file.getText();
	String resultFile= fname.substring(0, fname.length()-3)+"xml";
	String serverURL= c_server.getText();
	serverURL+= "?forUser="+ c_user.getText();
	//serverURL+= "&forPassword="+ c_passw.getText();
	out( "serverURL: "+ serverURL);
	result= uploadFile( fname, serverURL, resultFile);
	out( "uploadFile: "+ result);
	c_info.setText( result);
	b_run.setEnabled( true);
	setCursor( Cursor.getDefaultCursor());
}
}

//--------------------------
//WindowListener

public void windowActivated(WindowEvent e)
{
}
public void windowClosed(WindowEvent e)
{
}
public void windowClosing(WindowEvent e)
{
removeWindowListener( this);
b_run.removeActionListener( this);
dispose();
System.exit(0);
}
public void windowDeactivated(WindowEvent e)
{
}
public void windowDeiconified(WindowEvent e)
{
}
public void windowIconified(WindowEvent e)
{
}
public void windowOpened(WindowEvent e)
{
}

//--------------------------

private String login()
{
String url_string; 
url_string= c_server.getText() + "/gui/login.asp?command=bgLoginUser";
url_string+= "&" + "loginName=" + c_user.getText();
url_string+= "&" + "loginPass=" + c_passw.getText();
String result= "";
//result= url_string;
return result;
}

//--------------------------

public static String uploadFile(  String uploadFile, String uploadURL, String resultFile)
{
	out("uploadFile()");
	String response= "";
	boolean success= false;
	try
	{	
		byte bytebuf[]= new byte[2048];
		URLConnection urlcon= null;
		OutputStream os= null;
		DataOutputStream dos= null;
		URL u= new URL(uploadURL);
		if( u==null)
			return "URL error";
		urlcon= u.openConnection();
		if( urlcon==null)
			return "Connetction error";
		urlcon.setDoOutput( true);
		urlcon.setDoInput( true);
		urlcon.setUseCaches( false);
			
		//urlcon.setRequestMethod("POST");
		//urlcon.setRequestProperty("Content-Type", "application/x-www-form-urlencoded" );
		//urlcon.setRequestProperty("Content-Length", ""+lng );
		os = urlcon.getOutputStream();
		dos= new DataOutputStream(os);
		if( dos==null)
			return "POST DataOutputStream error";
		
		DataInputStream dis= null;
		dis= new  DataInputStream( new FileInputStream( uploadFile));
		if( dis==null)
			return "FileInputStream error";
		int lng= 0;
		for(;;)
		{
			int lng1= dis.read( bytebuf, 0, 2048);
			if( lng1<0)
				break;
			if( lng1==0)
				continue;
			dos.write( bytebuf, 0, lng1);
			lng+= lng1;
		}
		dis.close();
		dos.flush();
		dos.close();
		out( ""+ lng +" bytes sent to server");
		
		// get the post response
		DataInputStream is2 = new DataInputStream( 
			                       new BufferedInputStream(
								         urlcon.getInputStream()));
		dos= new  DataOutputStream( new FileOutputStream( resultFile));
		lng= 0;
		for(;;)
		{
			int lng1= is2.read( bytebuf, 0, 2048);
			if( lng1<0)
				break;
			if( lng1==0)
				continue;
			dos.write( bytebuf, 0, lng1);
			if( lng==0)
			{
				// save first part of response
				response= new String( bytebuf, 0, lng1);
			}
			lng+= lng1;
		}
		is2.close();
		dos.flush();
		dos.close();
		out( ""+ lng +" bytes received from server");
		out( "resultFile= "+ resultFile);

		success= true;
		if( response.startsWith("<Err")==true )
		{
			error( response);
			response= "ERROR: "+ response;
		}
		else
		{
			response= "OK";
		}
	}
	catch( Exception e)
	{
		response= "Upload error "+ e;
		error( response);
		success= false;
	}
	
	return response;
}

//--------------------------
//--------------------------

public static void error(String s)
{
System.out.println(s);
}// ReadProdAttrib(String Channel)

//--------------------------

public static void out(String s)
{
System.out.println(s);
}// ReadProdAttrib(String Channel)

//--------------------------

public static boolean isMSJave()
{
    String JavaVendor = java.lang.System.getProperty("java.vendor");  // tells who made it
	out("JavaVendor="+ JavaVendor);
	if( JavaVendor.startsWith("Microsoft")==true)
	{
		return true;
	}
	return false;
}

//--------------------------

public static void main (String args[])
{
out("Dialog to upload files to Web server");
httpupload dlg= new httpupload();
dlg.show();
}


//--------------------------
//--------------------------
//--------------------------



//--------------------------

}
