<%
// getCrystalData.jsp
//
// called by blu-ice / dcss
//
// http://gwolfpc:8081/cts/getCrystalData.jsp?forBeamLine=smbdcsdev&forCassetteIndex=1
// http://smb.slac.stanford.edu:8084/crystals/getCrystalData.jsp?forBeamLine=smblx6&forCassetteIndex=3
//
%>



<%@page contentType="text/html"%>
<%@ page import="java.io.*"%>

<%@include file="config.jsp" %>

<%!
//============================================================
// variable declarations

HttpServletRequest s_request;
HttpServletResponse s_response;
JspWriter s_out;
%>

<%
//============================================================
// vaiable initialisation

s_request= request;
s_response= response;
s_out= out;
%>

<%!
//============================================================
//============================================================
// server side script

public void processRequest()
     throws IOException
{
// filePath1= obj.getParameterValue( "beamlineDir");
//String filePath1= "C:\\Inetpub\\wwwroot\\cts\\data\\beamlines\\";
String filePath1= g_beamlineDir;

String forBeamLine= ""+s_request.getParameter("forBeamLine");
String forUser= ""+s_request.getParameter("forUser");
String forCassetteIndex= ""+s_request.getParameter("forCassetteIndex");

forBeamLine= getBeamlineName( forBeamLine);

String beamlinePosition;
switch( forCassetteIndex.charAt(0) )
{
	case '0': beamlinePosition= "no_cassette"; break;
	case '1': beamlinePosition= "left"; break;
	case '2': beamlinePosition= "middle"; break;
	case '3': beamlinePosition= "right"; break;
	default: beamlinePosition= "undefined"; break;
}

filePath1= filePath1 +File.separator+ forBeamLine +File.separator +"inuse_"+ beamlinePosition +".txt";

Reader src;
Writer dest;
src= new FileReader( filePath1);
dest= s_response.getWriter();
//dest= s_out;
char buf[]= new char[16000];
for(;;)
{
	int len= src.read(buf);
	if( len<0) break;
	dest.write(buf,0,len);
}
src.close();
dest.close();
}

// server side script
//==============================================================
//==============================================================
%>

<%
//response.setContentType("text/html");
processRequest();
%>
