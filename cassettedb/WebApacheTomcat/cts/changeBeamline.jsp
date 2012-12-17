<%
// changeBeamline.jsp
//
// called by the Web page CassetteInfo.jsp
//
//
%>


<%@ page language="java" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>

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
s_request= request;
s_response= response;
s_application= application;
s_out= out;
s_db= ctsdb;
s_io= ctsio;
%>

<%!
//============================================================
// server side function with HTML output

//==============================================================

void main()
    throws IOException
{
//String accessID= ""+s_request.getParameter("accessID");
String accessID= getAccessID( s_request);
String userName= ""+s_request.getParameter("userName");
String forCassetteID= ""+s_request.getParameter("forCassetteID");
String forBeamlineID= ""+s_request.getParameter("forBeamlineID");

if( checkAccessID( accessID, userName, s_response)==false )
{
	//s_out.println("invalid accessID");
	return;
}

String url= "CassetteInfo.jsp?accessID="+ accessID;
url+= "&userName="+ userName;

/*
//test
accessID="gwolf";
forCassetteID="2";
forBeamlineID="0";
*/

String beamlineName;
String beamlinePosition;
int cassetteID= Integer.valueOf( forCassetteID.trim() ).intValue();
int beamlineID= Integer.valueOf( forBeamlineID.trim() ).intValue();
beamlineName= s_db.getBeamlineName(beamlineID);

Properties loginProp= getLoginProp( accessID);
if( hasUserBeamtime( loginProp,beamlineName)==false )
{
    String accessIDUserName= loginProp.getProperty("userName");
    String msg= "<HTML>";
    msg+= "<HEADER>\r\n";
    msg+= "<TITLE>Crystal Cassette Tracking System</TITLE>\r\n";
    msg+= "</HEADER>\r\n";
    msg+= "<BODY>\r\n";
    msg+= "<H2>Crystal Cassette Tracking System</H2>\r\n";
    msg+= "ERROR\r\n";
    msg+= "<BR>\r\n";
    msg+= "The user '"+ accessIDUserName +"' has currently no access rights for the beamline '"+ beamlineName +"'.";
    msg+= "<BR>\r\n";
    msg+= "Please wait for your scheduled beamtime and select then the beamline position for your cassette.";
    msg+= "<BR>\r\n";
    msg+= "Please contact user support if you have currently beamtime at beamline "+ beamlineName;
    msg+= "<BR>\r\n";
    msg+= "<BR>\r\n";

    msg+= "<A HREF='"+ url +"'>\r\n";
    msg+= "Back to Crystal Cassette Information\r\n";
    msg+= "</A>\r\n";

    msg+= "<BR>\r\n";
    msg+= "</BODY>\r\n";
    msg+= "</HTML>\r\n";
    s_out.println(msg);
    return;
}

s_out.println("changeBeamline");
s_out.println("accessID="+ accessID);
s_out.println("userName="+ userName);
s_out.println("forCassetteID="+ forCassetteID);
s_out.println("forBeamlineID="+ forBeamlineID);

String x= "";
int userID= s_db.getUserID( userName);
if( userID<=0)
{
	//Error
	s_out.println( "<Error>Wrong username"+ userName +"</Error>");
	return;
}
String beamlineName_Position= s_db.mountCassette( cassetteID, beamlineID);
x=  beamlineName_Position;
if( x.length()>4 && x.substring(0,4).equalsIgnoreCase("<Err"))
{
	//Error
	s_out.println( beamlineName_Position);
	return;
}

beamlineName= "";
beamlinePosition= "";
int i;
i= beamlineName_Position.lastIndexOf('_');
if( i>0)
{
    beamlineName= beamlineName_Position.substring(0,i);
    beamlinePosition= beamlineName_Position.substring(i+1,beamlineName_Position.length());
    beamlinePosition= beamlinePosition.replace(' ', '_').toLowerCase();
}

s_out.println( "beamlineName="+ beamlineName);
s_out.println( "beamlinePosition="+ beamlinePosition);

if( beamlineName.length()>0)
{
	x= createBeamlineInfo( accessID, beamlineName);
}
if( x.length()>4 && x.substring(0,4).equalsIgnoreCase("<Err") )
{
	//Error
	s_out.println( x);
	return;
}

//out("beamlineName.length="+beamlineName.length);
if( beamlineName.length()>0)
{
    x= copyFilesToBeamline( userName, cassetteID, beamlineName, beamlinePosition);
}
if( x.length()>4 && x.substring(0,4).equalsIgnoreCase("<Err") )
{
	//Error
	s_out.println( x);
	return;
}

s_out.println("url="+ url);
s_out.println("s_response="+ s_response);
s_response.sendRedirect( url);
}

//==============================================================

boolean hasUserBeamtime( Properties loginProp, String beamlineName)
{
if( beamlineName==null || beamlineName.equalsIgnoreCase("None") || beamlineName.equalsIgnoreCase("SMBLX6") )
{
    return true;
}
boolean hasUserBeamtime= false;

String beamlineList= loginProp.getProperty("beamlineList");
//s_out.println("beamlineList="+ beamlineList);
//s_out.println("beamlineName="+ beamlineName);

StringTokenizer st= new  StringTokenizer(beamlineList, " ;,.\t\n\r");
while (st.hasMoreTokens())
{
    String enabledBeamline= st.nextToken();
    if( enabledBeamline.equalsIgnoreCase("ALL"))
    {
        hasUserBeamtime= true;
        break;
    }
    enabledBeamline= getBeamlineName( enabledBeamline);
    if( enabledBeamline==null)
    {
        continue;
    }
    if( enabledBeamline.equalsIgnoreCase(beamlineName))
    {
        hasUserBeamtime= true;
        break;
    }
}
return hasUserBeamtime;
}

//==============================================================

String createBeamlineInfo( String userName, String beamlineName)
{
//String result= "";
String xmlString= s_db.getCassettesAtBeamline(beamlineName);
String fileXSL1= "cassettesAtBeamline.xsl";
fileXSL1= s_application.getRealPath( fileXSL1);
//out.println(fileXSL1);

try
{
//s_out.println( "beamlineName="+beamlineName);
//s_out.println( "xmlString="+xmlString);

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

String copyFilesToBeamline( String userName, int cassetteID, String beamlineName, String beamlinePosition)
{
String x= "";
try
{
String cassetteDir= s_db.getParameterValue( "cassetteDir");
String beamlineDir= s_db.getParameterValue( "beamlineDir");
String fileName= s_db.getCassetteFileName( cassetteID);
x= fileName;
if( x.length()>4 && x.substring(0,4).equalsIgnoreCase("<Err") )
{
	return x;
}

cassetteDir= cassetteDir+ userName +File.separator;
beamlineDir= beamlineDir+ beamlineName +File.separator;

//out( "cassetteDir="+ cassetteDir);
//out( "beamlineDir="+ beamlineDir);

File fso = new File( beamlineDir);
if( fso.exists()==false )
{
	fso.mkdir();
}

String ext;
String filepath1= cassetteDir+ fileName;
String filepath2= beamlineDir+ beamlinePosition;
Reader src;
Writer dest;
char buf[]= new char[16000];

s_out.println( "filepath1="+ filepath1);
s_out.println( "filepath2="+ filepath2);

ext= ".xml";
x= s_io.copy( filepath1+ext, filepath2+ext);
if( x.length()>4 && x.substring(0,4).equalsIgnoreCase("<Err") )
{
    return x;
}

ext= ".txt";
s_io.copy( filepath1+ext, filepath2+ext);
if( x.length()>4 && x.substring(0,4).equalsIgnoreCase("<Err") )
{
    return x;
}

x= fileName;
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

