package org.apache.jsp;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
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

public final class BeamlineInfo_jsp extends org.apache.jasper.runtime.HttpJspBase
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
String s_accessID;
String s_userName;
int s_userID;
boolean s_hasStaffPrivilege;
String s_getCassetteURL;
String s_changeBeamlineURL;
ServletContext s_application;
JspWriter s_out;
CassetteDB s_db;
CassetteIO s_io;


//============================================================
// server side function with HTML output

void emitClientSideSriptParameters()
    throws IOException
{
String data="";

data+= "<SCRIPT id=\"event\" language=\"javascript\">";
data+= "\r\n";
data+= "<!--";
data+= "\r\n";
data+= "c_changeBeamlineURL= \""+ s_changeBeamlineURL +"\"";
data+= "\r\n";
data+= "//-->";
data+= "\r\n";
data+= "</SCRIPT>";
data+= "\r\n";

s_out.write( data);
}

//============================================================

void emitBeamlineTable( boolean hasStaffPrivilege)
    throws IOException
{
String xml1= s_db.getCassettesAtBeamline(null);
String fileXSL1= "createBeamlineTable.xsl";
String[] paramArray = new String[1];
paramArray[0]= ""+hasStaffPrivilege;

fileXSL1= s_application.getRealPath( fileXSL1);
s_io.xslt( xml1, s_out, fileXSL1, paramArray);

//htmlDoc.save( Response);
//Response.Write( ""+htmlDoc.xml);
}

// server side script
//============================================================
//============================================================

  private static java.util.List _jspx_dependants;

  static {
    _jspx_dependants = new java.util.ArrayList(2);
    _jspx_dependants.add("/config.jsp");
    _jspx_dependants.add("/pageheader.jsp");
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


// BeamlineInfo.jsp
//

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

// disable browser cache
response.setHeader("Expires","-1");

      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");

out.clear();

// variable initialisation
s_accessID= "" + ServletUtil.getSessionId(request);
s_userName= "" + ServletUtil.getUserName(request);
// Note that a staff user can select on this Web page another "userName",
// i.e. the login name derived from the "accessID" can be different from the "userName".
// However we do not allow this for Non-staff users.
checkAccessID(request, response);

s_getCassetteURL= getConfigValue( "getCassetteURL");
s_changeBeamlineURL= "assignSilToBeamline.jsp";

s_application= application;
s_out= out;
s_db= ctsdb;
s_io= ctsio;

Hashtable hash = gate.getProperties();
String userStaff = (String)hash.get("Auth.UserStaff");
s_hasStaffPrivilege = ServletUtil.isTrue(userStaff);
// Was there a parameter userName in the http querystring?
if((s_userName.length() == 0) || s_userName.equals("null") )
{
    // No -> derive the username from the accessID
	s_userName = gate.getUserID();
}
s_userID= ctsdb.getUserID( s_userName);

      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("<html>\r\n");
      out.write("\r\n");
      out.write("<head>\r\n");
      out.write("<title>Sample Database</title>\r\n");
      out.write("</head>\r\n");
      out.write("<body bgcolor=\"#FFFFFF\">\r\n");
      out.write("\r\n");

// pageheader.jsp
// define the header line for web pages of the Crystal Cassette Tracking System
// load different header depending on the installation site.

   String pageHeader = getConfigValue("pageheader");
   
   if ((pageHeader == null) || (pageHeader.length() == 0))
   	pageHeader = "ssrlheader.jsp";

      out.write("\r\n");
      out.write("\r\n");
      org.apache.jasper.runtime.JspRuntimeLibrary.include(request, response,  pageHeader , out, false);
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
 emitClientSideSriptParameters(); 
      out.write("\r\n");
      out.write("\r\n");
      out.write("<SCRIPT id=\"event\" language=\"javascript\">\r\n");
      out.write("<!--\r\n");
      out.write("//========================================================================\r\n");
      out.write("//========================================================================\r\n");
      out.write("// client side script\r\n");
      out.write("\r\n");
      out.write("function remove_onclick( cassetteID) {\r\n");
      out.write("    var submit_url = c_changeBeamlineURL;\r\n");
      out.write("    submit_url+= \"?accessID=\"+ document.form1.accessID.value;\r\n");
      out.write("    var x= document.form1.userName.value;\r\n");
      out.write("    submit_url+= \"&userName=\"+ x;\r\n");
      out.write("    submit_url+= \"&forCassetteID=\" + cassetteID;\r\n");
      out.write("    submit_url+= \"&forBeamlineID=0\";\r\n");
      out.write("    submit_url+= \"&returnedUrl=BeamlineInfo.jsp\";\r\n");
      out.write("    location.replace(submit_url);\r\n");
      out.write("}\r\n");
      out.write("\r\n");
      out.write("function remove_onclick1( cassetteID) {\r\n");
      out.write("    var submit_url = c_changeBeamlineURL;\r\n");
      out.write("    submit_url+= \"?accessID=\"+ document.form1.accessID.value;\r\n");
      out.write("    var x= document.form1.userName.value;\r\n");
      out.write("    submit_url+= \"&userName=\"+ x;\r\n");
      out.write("    submit_url+= \"&forCassetteID=\" + cassetteID;\r\n");
      out.write("    submit_url+= \"&forBeamlineID=0\";\r\n");
      out.write("    //thisPage.navigateURL( submit_url);\r\n");
      out.write("    //window.location.href = submit_url;\r\n");
      out.write("    location.replace(submit_url);\r\n");
      out.write("}\r\n");
      out.write("\r\n");
      out.write("// client side script\r\n");
      out.write("//========================================================================\r\n");
      out.write("//========================================================================\r\n");
      out.write("//-->\r\n");
      out.write("</SCRIPT>\r\n");
      out.write("\r\n");
      out.write("<FORM id=\"form1\" method=\"post\" name=\"form1\">\r\n");
      out.write("<INPUT name=\"accessID\" type=\"hidden\" value=\"");
      out.print( s_accessID);
      out.write("\" />\r\n");
      out.write("<INPUT name=\"userName\" type=\"hidden\" value=\"");
      out.print( s_userName);
      out.write("\" />\r\n");
      out.write("<P>\r\n");
      out.write("At the SMB Beamlines are currently mounted the following Cassettes:\r\n");
      out.write("</P>\r\n");
      out.write("\r\n");
      out.write("<P>\r\n");
 emitBeamlineTable( s_hasStaffPrivilege); 
      out.write("\r\n");
      out.write("</P>\r\n");
      out.write("\r\n");
      out.write("</FORM>\r\n");
      out.write("\r\n");
      out.write("<BR>\r\n");
      out.write("<A class=\"clsLinkX\" HREF=\"CassetteInfo.jsp?accessID=");
      out.print( s_accessID);
      out.write("&userName=");
      out.print( s_userName);
      out.write("\">\r\n");
      out.write("Back</A>\r\n");
      out.write("to the Sample Database page for the user '");
      out.print( s_userName);
      out.write("'.\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("\r\n");
 if (gate.getUserID().equals("penjitk") || gate.getUserID().equals("scottm") || gate.getUserID().equals("jsong")) { 
      out.write("\r\n");
      out.write("<a href=\"addBeamlineForm.jsp?accessID=");
      out.print( s_accessID);
      out.write("&userName=");
      out.print( s_userName );
      out.write("\">Add beamline</a>\r\n");
 } 
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("</body>\r\n");
      out.write("</html>\r\n");
      out.write("\r\n");
      out.write("</body>\r\n");
      out.write("</html>\r\n");
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
