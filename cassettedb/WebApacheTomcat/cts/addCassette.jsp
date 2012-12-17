<%
// addCassette.jsp
//
// called by the Web page addCassetteForm.jsp
//
//
%>

<%@ page language="java" %>
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
String accessID= ""+s_request.getParameter("accessID");
String userName= ""+s_request.getParameter("userName");
String PIN_Number= ""+s_request.getParameter("PIN_Number");

checkAccessID( accessID, userName, s_response);
if( userName.equals("null") )
{
    Properties loginProp= getLoginProp(accessID);
    userName= loginProp.getProperty("userName");
}

/*
//test
accessID="gwolf";
PIN_Number="pin3";
*/

String url= "CassetteInfo.jsp?accessID="+ accessID;
url+= "&userName="+ userName;

if( PIN_Number.length()<=0)
{
    String msg= "<HTML>";
    msg+= "<HEADER>\r\n";
    msg+= "<TITLE>Crystal Cassette Tracking System</TITLE>\r\n";
    msg+= "</HEADER>\r\n";
    msg+= "<BODY>\r\n";
    msg+= "<H2>Crystal Cassette Tracking System</H2>\r\n";
    msg+= "ERROR\r\n";
    msg+= "<BR>\r\n";
    msg+= "The PIN number '"+ PIN_Number +"' is not correct.";
    msg+= "<BR>\r\n";
    msg+= "Please contact user support.";
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

s_out.println("addCassette");
s_out.println("accessID="+ accessID);
s_out.println("userName="+ userName);
s_out.println("PIN_Number="+ PIN_Number);


int userID= s_db.getUserID( userName);
String x= addCassette( userID, PIN_Number);
if( x.length()>4 && x.substring(0,4).compareToIgnoreCase("<Err")==0)
{
	s_out.println("userID="+ userID);
	s_out.println("ERROR "+ x);
	return;
}

s_response.sendRedirect( url);

}

//==============================================================

String addCassette( int userID, String PIN_Number)
{
String x= "";
try
{
x= s_db.addCassette( userID, PIN_Number);
if( x.length()>4 && x.substring(0,4).compareToIgnoreCase("<Err")==0)
{
	return x;
}

int cassetteID= Integer.valueOf( x.trim() ).intValue();

s_out.println( "cassetteID="+ cassetteID); 

String filePrefix= "excelData";
String userFileName= "default.xls";
String filePath1= s_db.getParameterValue( "templateDir")+ "cassette_template";
String cassetteDir= s_db.getParameterValue( "cassetteDir");
String userName= s_db.getUserName( userID);

cassetteDir= cassetteDir+ userName +"/";
File fso = new File(cassetteDir);
if( fso.exists()==false )
{
    fso.mkdir();
}
String archiveFileName= s_db.addCassetteFile( cassetteID, filePrefix, userFileName);
if( archiveFileName.length()>4 && archiveFileName.substring(0,4).compareToIgnoreCase("<Err")==0)
{
	x= archiveFileName;
	return x;
}

String ext;
String filePath2= cassetteDir+ archiveFileName;

ext= "_src.xls";
x= s_io.copy( filePath1+ext, filePath2+ext);
if( x.length()>4 && x.substring(0,4).equalsIgnoreCase("<Err") ) { return x; }

ext= "_src.xml";
x= s_io.copy( filePath1+ext, filePath2+ext);
if( x.length()>4 && x.substring(0,4).equalsIgnoreCase("<Err") ) { return x; }

ext= ".xml";
x= s_io.copy( filePath1+ext, filePath2+ext);
if( x.length()>4 && x.substring(0,4).equalsIgnoreCase("<Err") ) { return x; }

ext= ".html";
x= s_io.copy( filePath1+ext, filePath2+ext);
if( x.length()>4 && x.substring(0,4).equalsIgnoreCase("<Err") ) { return x; }

ext= ".txt";
x= s_io.copy( filePath1+ext, filePath2+ext);
if( x.length()>4 && x.substring(0,4).equalsIgnoreCase("<Err") ) { return x; }

x= archiveFileName;
}
catch( Exception ex)
{
    x="<Error> addCassette()"+ ex +"</Error>";
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
