/*
 * CassetteIO.java
 *
 * Created on September 18, 2002, 1:05 PM
 */


package cts;

import javax.xml.transform.*;
import javax.xml.transform.stream.*;
import java.io.*;

public class CassetteIO {

    /** Creates new CassetteIO */
    public CassetteIO() {
    }

//============================================================
// CassetteInfo

public void xslt( String xmlString, Writer outStream, String xslFileName, String[] paramArray)
    throws IOException 
{
String xml1= xmlString;
String fileXSL1= xslFileName;

//fileXSL1= s_application.getRealPath( fileXSL1);
//out.write(fileXSL1);

try
{
TransformerFactory tFactory = TransformerFactory.newInstance();
Transformer transformer = tFactory.newTransformer( new StreamSource( fileXSL1));

// prepare parameters for xslt
int n= 0;
if( paramArray!=null)
{
    n= paramArray.length;
}
for( int i=0; i<n; i++)
{
    String paraName= "param"+ (i+1);
    String paraVal= paramArray[i];
    transformer.setParameter( paraName, paraVal);
    //s_out.write( "paraName="+ paraName);
    //s_out.write( "paraVal="+ paraVal);
}

//DOMSource source = new DOMSource(document);
StreamSource source = new StreamSource( new StringReader( xmlString));
StreamResult result = new StreamResult( outStream);
transformer.transform( source, result);
}
catch( Exception ex)
{
   String data= "<Error>"+ ex +"</Error>";
   outStream.write( data);
}
//return xmlDoc2;
}

//============================================================
//============================================================
// CassetteIO

public String xslt( String srcFile, String destFile, String xslFileName, String[] paramArray)
    throws IOException 
{
//s_out.println("xslt <BR>\r\n");
//s_out.println("srcFile="+ srcFile +"<BR>\r\n");
//s_out.println("destFile="+ destFile +"<BR>\r\n");
//s_out.println("xslFileName="+ xslFileName +"<BR>\r\n");

String x= "";
try
{
TransformerFactory tFactory = TransformerFactory.newInstance();
Transformer transformer = tFactory.newTransformer( new StreamSource( new FileReader( xslFileName)));

// prepare parameters for xslt
int n= 0;
if( paramArray!=null)
{
    n= paramArray.length;
}
for( int i=0; i<n; i++)
{
    String paraName= "param"+ (i+1);
    String paraVal= paramArray[i];
    transformer.setParameter( paraName, paraVal);
    //s_out.write( "paraName="+ paraName);
    //s_out.write( "paraVal="+ paraVal);
}

//DOMSource source = new DOMSource(document);
StreamSource source = new StreamSource( new FileReader( srcFile));
StreamResult result = new StreamResult( new FileWriter( destFile));
transformer.transform( source, result);
x= "OK";
}
catch( Exception ex)
{
    x= "<Error>"+ ex +"</Error>";
}

return x;
}

//============================================================
//============================================================
// addCassette.jsp
// upload.jsp

public String copy( String source, String destination)
{
	//out.println("copy()");
	String response= "";
	try
	{	
		FileInputStream is= new FileInputStream( source);
		if( is==null)
			return "FileInputStream error";
		response= copyFileStream( is, destination);
	}
	catch( Exception e)
	{
		response= "<Error> copy() "+ e +"</Error>";
		//error( response);
	}
	
return response;
}

//============================================================

public String copyFileStream( InputStream ins, String destination)
{
	String response= "";
try
{	
	DataInputStream dis = new DataInputStream( new BufferedInputStream( ins));
	FileOutputStream outputFile = new FileOutputStream(destination);
      DataOutputStream dos = new DataOutputStream(outputFile);
      byte bytebuf[]= new byte[2048];
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
        dos.close();
        response= "OK";
}
catch( IOException e)
{
	response= "<Error>copyFileStream() "+ e +"<Error>";
	//error( response);
}
return response;
}

//============================================================


}
