<%
// updateCrystalData.jsp
//
// called by blu-ice
//
%>


<%@ page language="java" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>

<%@include file="config.jsp" %>

<%!
//============================================================
//============================================================
// server side script

// variable declarations
HttpServletRequest s_request;
HttpServletResponse s_response;
ServletContext s_application;
JspWriter s_out;
CassetteDB s_db;
CassetteIO s_io;
%>

<%
// variable initialisation
s_db= ctsdb;
s_io= ctsio;
s_request= request;
s_response= response;
s_application= application;
s_out= out;
%>

<%!
//============================================================
// server side function with HTML output


//==============================================================

void main()
    throws IOException
{
doUpdateCrystalData();
}

//==============================================================
//==============================================================

void doUpdateCrystalData()
    throws IOException
{
// copy crystalData.xml -> inuse_blctl111.xml
//
String forBeamLine= ""+s_request.getParameter("forBeamLine");
forBeamLine= getBeamlineName( forBeamLine);
String forUser= ""+s_request.getParameter("forUser");

String x;
x= createBeamlineInfo( forUser, forBeamLine);
if( x.length()>4 && x.substring(0,4).compareToIgnoreCase("<Err")==0)
{
	//Error
	s_out.println( x);
	return;
}
x= copyFilesToInUse( forBeamLine);
if( x.length()>4 && x.substring(0,4).compareToIgnoreCase("<Err")==0)
{
	//Error
	s_out.println( x);
	return;
}

s_out.print( "ok");

return;
}

//==============================================================

String createBeamlineInfo( String userName, String beamlineName)
{
//String result= "";
String xmlString= s_db.getCassettesAtBeamline(beamlineName);
String fileXSL1= "cassettesAtBeamline.xsl";
//out( xml1);

fileXSL1= s_application.getRealPath( fileXSL1);
//out.println(fileXSL1);

try
{
//s_out.print( "xmlString="+ xmlString);

StringWriter tclStringWriter= new StringWriter();

s_io.xslt( xmlString, tclStringWriter, fileXSL1, null);

String tcldata= tclStringWriter.toString();
String x= tcldata;
if( x.length()>4 && x.substring(0,4).equalsIgnoreCase("<Err") ) { return x; }

//save beamline info to disk
String beamlineDir= s_db.getParameterValue( "beamlineDir")+ beamlineName +File.separator;
File fso = new File(beamlineDir);
if( fso.exists()==false )
{
	fso.mkdir();
}
Writer dest;
String filepath;
filepath= beamlineDir+ "cassettes.xml";
dest= new FileWriter( filepath);
dest.write( xmlString);
dest.close();
filepath= beamlineDir+ "cassettes.txt";
dest= new FileWriter( filepath);
dest.write( tcldata);
dest.close();
//s_out.print( "filepath="+ filepath);
}
catch( Exception ex)
{
   String data= "<Error>"+ ex +"</Error>";
   //s_out.println( data);
   return data;
}


return "OK";
}

//==============================================================

String copyFilesToInUse( String beamlineName)
{
String x= "";
try
{
String beamlineDir= s_db.getParameterValue( "beamlineDir");
beamlineDir= beamlineDir+ beamlineName +File.separator;

//s_out.println( "beamlineDir="+ beamlineDir);

File fso = new File( beamlineDir);
if( fso.exists()==false )
{
	fso.mkdir();
}

String ext;
String filepath1= beamlineDir;
String filepath2= beamlineDir+ "inuse_";

//out( "filepath1="+ filepath1);
//out( "filepath2="+ filepath2);

ext= "cassettes.xml";
if( new File(filepath1+ext).exists() )
{
    x= s_io.copy(filepath1+ext,filepath2+ext);
    if( x.length()>4 && x.substring(0,4).compareToIgnoreCase("<Err")==0)
    {
	return x;
    }
}
ext= "cassettes.txt";
s_io.copy(filepath1+ext,filepath2+ext);
if( new File(filepath1+ext).exists() )
{
    x= s_io.copy(filepath1+ext,filepath2+ext);
    if( x.length()>4 && x.substring(0,4).compareToIgnoreCase("<Err")==0)
    {
	return x;
    }
}

ext= "no_cassette.xml";
s_io.copy(filepath1+ext,filepath2+ext);
ext= "no_cassette.txt";
s_io.copy(filepath1+ext,filepath2+ext);

ext= "left.xml";
s_io.copy(filepath1+ext,filepath2+ext);
ext= "left.txt";
s_io.copy(filepath1+ext,filepath2+ext);

ext= "middle.xml";
s_io.copy(filepath1+ext,filepath2+ext);
ext= "middle.txt";
s_io.copy(filepath1+ext,filepath2+ext);

ext= "right.xml";
s_io.copy(filepath1+ext,filepath2+ext);
ext= "right.txt";
s_io.copy(filepath1+ext,filepath2+ext);
x= "ok";
}
catch( Exception ex)
{
    x="<Error> copyFilesToBeamline()"+ ex +"</Error>";
}

return x;
}


// server side script
//============================================================
//============================================================
%>
<%
main();
%>
