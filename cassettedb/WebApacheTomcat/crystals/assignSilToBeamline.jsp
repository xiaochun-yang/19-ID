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
<%@ page import="sil.beans.*" %>

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
String s_url = "";
AuthGatewayBean s_gate;
%>

<%
// variable initialisation
s_request= request;
s_response= response;
s_application= application;
s_out= out;
s_db= ctsdb;
s_io= ctsio;
s_gate = gate;
%>

<%!
//============================================================
// server side function with HTML output

//==============================================================

void main()
    throws IOException
{
//String accessID= ""+s_request.getParameter("accessID");
String accessID= "" + ServletUtil.getSessionId(s_request);
String userName= "" + ServletUtil.getUserName(s_request);
String forCassetteID= ""+s_request.getParameter("forCassetteID");
String forBeamlineID= ""+s_request.getParameter("forBeamlineID");
String returnedUrl= s_request.getParameter("returnedUrl");

if( checkAccessID(s_request, s_response)==false )
{
	//s_out.println("invalid accessID");
	return;
}

String url = "";
if ((returnedUrl != null) && (returnedUrl.length() > 0))
	url = returnedUrl;
else
	url = "CassetteInfo.jsp";

url += "?accessID="+ accessID + "&userName="+ userName;

s_url = url;

String beamlineName = "";
String beamlinePosition = "";
int cassetteID= Integer.valueOf( forCassetteID.trim() ).intValue();
int beamlineID= Integer.valueOf( forBeamlineID.trim() ).intValue();
beamlineName= s_db.getBeamlineName(beamlineID);

if( hasUserBeamtime(beamlineName)==false )
{
    String accessIDUserName= s_gate.getUserID();
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
    msg+= "Back to Sample Database page\r\n";
    msg+= "</A>\r\n";

    msg+= "<BR>\r\n";
    msg+= "</BODY>\r\n";
    msg+= "</HTML>\r\n";
    s_out.println(msg);
    return;
}

String x= "";
int userID= s_db.getUserID( userName);
if( userID<=0)
{
	//Error
	s_out.println( "<Error>Wrong username"+ userName +"</Error>");
	return;
}

String silId = forCassetteID;
String forUser = userName;
String forBeamLine = "";
int bid = beamlineID;
try {

	int id = -1;
	try {
		id = Integer.parseInt(silId);
	} catch (NumberFormatException e) {
		throw new Exception("Invalid cassette ID " + silId);
	}

	SilManager manager = new SilManager(s_db, s_io);

	if (bid > 0) {

		Hashtable ret = s_db.getBeamlineInfo(bid);

		forBeamLine = ((String)ret.get("BEAMLINE_NAME")).toUpperCase();
		beamlinePosition = (String)ret.get("BEAMLINE_POSITION");
		
		if ((forBeamLine == null) || (forBeamLine.length() == 0))
			throw new Exception("Invalid beamline name for beamline id = " + bid);

		if ((beamlinePosition == null) && (beamlinePosition.length() == 0))
			throw new Exception("Invalid beamline position name for beamline id = " + bid);

		// Copy sil files to beamline dir
		// Copy all sils at the beamline to inuse
		// so that bluice can load them
		manager.assignSilToBeamline(id, forBeamLine, beamlinePosition);

	} else {

		manager.unassignSil(id);
	}



	s_out.println("url="+ url);
	s_out.println("s_response="+ s_response);
	s_response.sendRedirect(url);

	} catch (Exception e) {
		gotoErrorPage(e.getMessage());
	}


}

/**
 * Display error page
 */
void gotoErrorPage(String err)
{
	try {
	StringBuffer msg = new StringBuffer();
	msg.append("<html>");
	msg.append("<head></head>");
	msg.append("<body>");
	msg.append("<h2 style=\"color: red\">ERROR: Cannot assign cassette to beamline</h2>");
	msg.append("<pre>");
	msg.append(err);
	msg.append("</pre>");
	msg.append("<br><br>");
	msg.append("<form action=\"" + s_url + "\">");
	msg.append("<input type=\"submit\" value=\"Casstte List\"/>");
	msg.append("</form>");
	msg.append("</body>");
	msg.append("</html>");

	s_out.println(msg);

	} catch (Exception e) {
		SilLogger.error("Error in assignSilToBeamline.jsp: " + err);
	}

}

//==============================================================

boolean hasUserBeamtime(String beamlineName)
{
	if( beamlineName==null || beamlineName.equalsIgnoreCase("None") || beamlineName.equalsIgnoreCase("SMBLX6") )
	{
    			return true;
	}
	boolean hasUserBeamtime= false;

	Hashtable hash = s_gate.getProperties();
	String allowedBeamlines = (String)hash.get("Auth.Beamlines");
	if (allowedBeamlines.equals("ALL"))
		return true;
		
	StringTokenizer tok = new StringTokenizer(allowedBeamlines, ";");
	while (tok.hasMoreTokens()) {
		if (tok.nextToken().equalsIgnoreCase(beamlineName))
			return true;
	}

	return false;
}


// server side script
//============================================================
//============================================================
%>


<%
main();
%>

