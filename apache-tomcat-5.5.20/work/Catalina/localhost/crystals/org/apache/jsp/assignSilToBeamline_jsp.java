package org.apache.jsp;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import java.io.*;
import java.util.*;
import sil.beans.*;
import java.io.*;
import java.util.Hashtable;
import java.util.Properties;
import java.util.Enumeration;
import cts.CassetteDB;
import cts.CassetteDBFactory;
import cts.CassetteIO;
import sil.beans.SilUtil;
import sil.beans.SilConfig;
import sil.beans.SilLogger;
import sil.servlets.ServletUtil;
import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;

public final class assignSilToBeamline_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {


//============================================================
// global variables (declaration)
HttpSession g_session;
AuthGatewayBean g_gate;
CassetteDB ctsdb;



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

  private static java.util.List _jspx_dependants;

  static {
    _jspx_dependants = new java.util.ArrayList(1);
    _jspx_dependants.add("/config.jsp");
  }

  public Object getDependants() {
    return _jspx_dependants;
  }

  public void _jspService(HttpServletRequest request, HttpServletResponse response)
        throws java.io.IOException, ServletException {

    JspFactory _jspxFactory = null;
    PageContext pageContext = null;
    HttpSession session = null;
    ServletContext application = null;
    ServletConfig config = null;
    JspWriter out = null;
    Object page = this;
    JspWriter _jspx_out = null;
    PageContext _jspx_page_context = null;


    try {
      _jspxFactory = JspFactory.getDefaultFactory();
      response.setContentType("text/html");
      pageContext = _jspxFactory.getPageContext(this, request, response,
      			null, true, 8192, true);
      _jspx_page_context = pageContext;
      application = pageContext.getServletContext();
      config = pageContext.getServletConfig();
      session = pageContext.getSession();
      out = pageContext.getOut();
      _jspx_out = out;


// changeBeamline.jsp
//
// called by the Web page CassetteInfo.jsp
//
//

      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");

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

      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      cts.CassetteIO ctsio = null;
      synchronized (session) {
        ctsio = (cts.CassetteIO) _jspx_page_context.getAttribute("ctsio", PageContext.SESSION_SCOPE);
        if (ctsio == null){
          ctsio = new cts.CassetteIO();
          _jspx_page_context.setAttribute("ctsio", ctsio, PageContext.SESSION_SCOPE);
        }
      }
      out.write("\r\n");
      out.write("\r\n");
      edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean gate = null;
      synchronized (session) {
        gate = (edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean) _jspx_page_context.getAttribute("gate", PageContext.SESSION_SCOPE);
        if (gate == null){
          gate = new edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean();
          _jspx_page_context.setAttribute("gate", gate, PageContext.SESSION_SCOPE);
        }
      }
      out.write('\r');
      out.write('\n');
      out.write("\r\n");
      out.write("\r\n");


//============================================================
// global variables (initialization)
g_session= session;
g_gate= gate;

if (gate == null)
	response.sendRedirect("loginForm.jsp");

ctsdb = SilUtil.getCassetteDB(); // singleton

      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write('\r');
      out.write('\n');
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");

// variable initialisation
s_request= request;
s_response= response;
s_application= application;
s_out= out;
s_db= ctsdb;
s_io= ctsio;
s_gate = gate;

      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");

main();

      out.write("\r\n");
      out.write("\r\n");
    } catch (Throwable t) {
      if (!(t instanceof SkipPageException)){
        out = _jspx_out;
        if (out != null && out.getBufferSize() != 0)
          out.clearBuffer();
        if (_jspx_page_context != null) _jspx_page_context.handlePageException(t);
      }
    } finally {
      if (_jspxFactory != null) _jspxFactory.releasePageContext(_jspx_page_context);
    }
  }
}
