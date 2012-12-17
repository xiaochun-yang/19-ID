<%
// config.jsp
// define parameters and JavaBeans for Crystal Cassette Tracking System
// provides basic functions to check the user access rights
//
// this file will be included by other JSP's with: %@include file="config.jsp"
//
// use JavaBean CassetteDB.class (WEB-INF/lib/cts.jar)
// to load XML from Oracle DB (with Oracle JDBC driver in WEB-INF/lib/classes111.jar)
//
// use JavaBean CassetteIO.class (WEB-INF/lib/cts.jar)
// for file-io, http transfer and xslt transformations
//
// use Java class AuthGatewayBean (WEB-INF/lib/authUtility.jar) to check user access rights
//  page import="edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean"
//
// define system configuration parameters like:
//   db connection parameters
//   directory path for file archive
//   beamline names
//   ...
// Most of the configuration parameters are loaded from the property file config.prop
// However some of them are hard coded in config.jsp:
//   db connection (DSN, userName, password)
//   normalized beamline names ( getBeamlineName())
//
// If you make a change in config.prop you should touch all jsp files
// touch *.jsp
// to make sure that Tomcat reloads all pages with the updated configuration
//
// If you add a beamline, you have to make changes in 3 places:
//   the db table beamline
//   the normalized beamline names in the function getBeamlineName() in config.jsp
//   create a new version of the xml-file beamlineList.xml with the help of getBeamlineList.jsp
//
%>

<%@ page import="java.io.*" %>
<%@ page import="java.util.Hashtable" %>
<%@ page import="java.util.Properties" %>
<%@ page import="java.util.Enumeration" %>
<%@ page import="cts.CassetteDB" %>
<%@ page import="cts.CassetteDBFactory" %>
<%@ page import="cts.CassetteIO" %>
<%@ page import="sil.beans.SilUtil" %>
<%@ page import="sil.beans.SilConfig" %>
<%@ page import="sil.beans.SilLogger" %>
<%@ page import="sil.servlets.ServletUtil" %>
<%@ page import="edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean" %>


<jsp:useBean id="ctsio" scope="session" class="cts.CassetteIO" />

<jsp:useBean id="gate" scope="session" class="edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean" />
<%!
//============================================================
// global variables (declaration)
HttpSession g_session;
AuthGatewayBean g_gate;
CassetteDB ctsdb;
%>

<%

//============================================================
// global variables (initialization)
g_session= session;
g_gate= gate;

if (gate == null)
	response.sendRedirect("loginForm.jsp");

ctsdb = SilUtil.getCassetteDB(); // singleton
%>


<%!

//==============================================================
//==============================================================
String getConfigValue(String paramName)
{
	String paramValue = SilConfig.getInstance().getProperty(paramName);
	if (paramValue==null) {
		String errmsg= "ERROR config.jsp getConfigValue() unknown property "+ paramName;
		errMsg(errmsg);
		return errmsg;
	}

	return paramValue;
}

%>

<%!
//==============================================================
boolean checkAccessID(HttpServletRequest myrequest, HttpServletResponse myresponse)
    throws IOException
{
	boolean validSession = ServletUtil.checkAccessID(myrequest, myresponse);
	
	AuthGatewayBean gate = (AuthGatewayBean)myrequest.getSession().getAttribute("gate");
		
	if (!validSession)
		myresponse.sendRedirect("loginForm.jsp");
		
	if ((gate != null) && (g_gate != gate))
		g_gate = gate;
		
	return validSession;
}

//==============================================================
void errMsg(String msg)
{
    SilLogger.error( msg);
}

//==============================================================
void errMsg(Throwable ex)
{
    SilLogger.error(ex.toString());
    SilLogger.error(ex);
}


//==============================================================
void errMsg(String msg, Throwable ex)
{
    SilLogger.error(msg + ex.toString());
    SilLogger.error(ex);
}

//==============================================================
void logMsg( String msg)
{
    SilLogger.info(msg);
}

%>
