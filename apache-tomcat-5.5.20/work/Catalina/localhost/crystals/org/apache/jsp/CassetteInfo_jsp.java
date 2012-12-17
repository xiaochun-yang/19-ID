package org.apache.jsp;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import java.util.Date;
import java.util.Vector;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.StringTokenizer;
import java.io.*;
import sil.beans.*;
import cts.CassetteInfo;
import cts.BeamlineInfo;
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

public final class CassetteInfo_jsp extends org.apache.jasper.runtime.HttpJspBase
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
String s_uploadURL;
String s_deleteCassetteURL;
String s_changeUserURL;
String s_changeBeamlineURL;
String s_addUserURL;
String s_addCassetteURL;
String s_uploadCassetteURL;
ServletContext s_application;
JspWriter s_out;
CassetteDB s_db;
CassetteIO s_io;
String s_startRange;
String s_endRange;
String s_numShow;


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
data+= "c_changeUserURL= \""+ s_changeUserURL +"\"";
data+= "\r\n";
data+= "c_changeBeamlineURL= \""+ s_changeBeamlineURL +"\"";
data+= "\r\n";
data+= "c_addUserURL= \""+ s_addUserURL +"\"";
data+= "\r\n";
data+= "c_addCassetteURL= \""+ s_addCassetteURL +"\"";
data+= "\r\n";
data+= "c_uploadCassetteURL= \""+ s_uploadCassetteURL +"\"";
data+= "\r\n";
data+= "//-->";
data+= "\r\n";
data+= "</SCRIPT>";
data+= "\r\n";

s_out.write( data);
}

//============================================================

void emitUserName( int userID, boolean hasStaffPrivilege)
    throws IOException
{
String data= "";
data+= "User name: ";
data+= "\r\n";
s_out.write( data);

String xml1= s_db.getUserList();
String fileXSL1= "createUserList.xsl";
String[] paramArray = new String[2];
paramArray[0]= ""+userID;
paramArray[1]= ""+hasStaffPrivilege;
fileXSL1= s_application.getRealPath( fileXSL1);
s_io.xslt( xml1, s_out, fileXSL1, paramArray);

return;
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


// CassetteInfo.jsp
//

      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("<\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");

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
      out.write('\n');
      out.write('\n');

// disable browser cache
response.setHeader("Expires","-1");

      out.write('\n');
      out.write('\n');
      out.write('\n');
      out.write('\n');
      out.write('\n');


out.clear();

// variable initialisation
s_accessID= "" + ServletUtil.getSessionId(request);
s_userName= "" + ServletUtil.getUserName(request);

s_numShow = request.getParameter("numShow");
s_startRange = request.getParameter("startRange");

// Note that a staff user can select on this Web page another "userName",
// i.e. the login name derived from the "accessID" can be different from the "userName".
// However we do not allow this for Non-staff users.
//logMsg("in CassetteInfo: s_accessID = " + s_accessID);
//logMsg("in CassetteInfo: s_userName = " + s_userName);
if( checkAccessID(request, response)==false )
{
	System.out.println("in CassetteInfo: checkAccessID returned false for user " + s_userName + " accessID = " + s_accessID);
	return;
}

if ((s_userName.length() == 0) || s_userName.equals("null")) {
	s_userName = gate.getUserID();
}

s_getCassetteURL= getConfigValue( "getCassetteURL");
s_uploadURL= "uploadForm.jsp";
s_deleteCassetteURL= "deleteCassetteForm.jsp";
s_changeUserURL= "changeUser.jsp";
s_changeBeamlineURL= "assignSilToBeamline.jsp";
s_addUserURL= "addUserForm.jsp";
s_addCassetteURL= "addCassetteForm.jsp";
s_uploadCassetteURL= "uploadForm.jsp";

s_application= application;
s_out= out;
s_db= ctsdb;
s_io= ctsio;

Hashtable hash1 = gate.getProperties();
String userStaff = (String)hash1.get("Auth.UserStaff");
s_hasStaffPrivilege = ServletUtil.isTrue(userStaff);	

// Was there a parameter userName in the http querystring?
if((s_userName.length() == 0) || s_userName.equals("null") )
{
	// No -> derive the username from the accessID
	s_userName = gate.getUserID();
}
s_userID= ctsdb.getUserID( s_userName);
// Does the cassette DB have already an ID for this user?
if( s_userID<0)
{
	// No -> add the user to the cassette DB
	String longUserName = gate.getUserID();
	s_db.addUser(s_userName,null,longUserName);
	s_userID= s_db.getUserID( s_userName);
}

      out.write('\n');
      out.write('\n');
      out.write("\n");
      out.write("\n");
      out.write("<html>\n");
      out.write("\n");
      out.write("<head>\n");
      out.write("<title>Sample Database</title>\n");
      out.write("</head>\n");
      out.write("<body id=\"CassetteInfo\" bgcolor=\"#FFFFFF\">\n");
      out.write("\n");

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
      out.write('\n');
      out.write('\n');
 emitClientSideSriptParameters(); 
      out.write("\n");
      out.write("\n");
      out.write("<SCRIPT id=\"event\" language=\"javascript\">\n");
      out.write("<!--\n");
      out.write("// client side script\n");
      out.write("//========================================================================\n");
      out.write("//========================================================================\n");
      out.write("\n");
      out.write("function user_onchange() {\n");
      out.write("    var i = document.form1.user.selectedIndex;\n");
      out.write("    var submit_url = c_changeUserURL;\n");
      out.write("    submit_url+= \"?accessID=\"+ document.form1.accessID.value;\n");
      out.write("    //var x= document.form1.user.options[i].value;\n");
      out.write("    var x= document.form1.user.options[i].text;\n");
      out.write("    submit_url+= \"&userName=\"+ x;\n");
      out.write("    //location.replace(submit_url);\n");
      out.write("    window.location.href = submit_url;\n");
      out.write("}\n");
      out.write("\n");
      out.write("//========================================================================\n");
      out.write("\n");
      out.write("function beamline_onchange( dropdownID, cassetteID) {\n");
      out.write("    eval( \"i = document.form1.\"+ dropdownID +\".selectedIndex\");\n");
      out.write("    var submit_url = c_changeBeamlineURL;\n");
      out.write("    //submit_url+= \"accessID={2E8BB7D0-851C-11D4-92A6-00010234AF2F}\";\n");
      out.write("    submit_url+= \"?accessID=\"+ document.form1.accessID.value;\n");
      out.write("    //var iuser = document.form1.user.selectedIndex;\n");
      out.write("    //var x= document.form1.user.options[iuser].text;\n");
      out.write("    var x= document.form1.userName.value;\n");
      out.write("    submit_url+= \"&userName=\"+ x;\n");
      out.write("    submit_url+= \"&forCassetteID=\" + cassetteID;\n");
      out.write("    eval(\"x= document.form1.\"+ dropdownID +\".options[i].value\");\n");
      out.write("    submit_url+= \"&forBeamlineID=\"+ x;\n");
      out.write("    //thisPage.navigateURL( submit_url);\n");
      out.write("    //window.location.href = submit_url;\n");
      out.write("    location.replace(submit_url);\n");
      out.write("}\n");
      out.write("\n");
      out.write("//========================================================================\n");
      out.write("\n");
      out.write("function uploadCassette_onclick()\n");
      out.write("{\n");
      out.write("var submit_url= c_uploadCassetteURL;\n");
      out.write("submit_url+= \"?accessID=\"+ document.form1.accessID.value;\n");
      out.write("var x= document.form1.userName.value;\n");
      out.write("submit_url+= \"&userName=\"+ x;\n");
      out.write("window.location.href = submit_url;\n");
      out.write("}\n");
      out.write("\n");
      out.write("//========================================================================\n");
      out.write("\n");
      out.write("function search()\n");
      out.write("{\n");
      out.write("var i = document.form1.searchBy.selectedIndex;\n");
      out.write("var val = document.form1.searchBy.options[i].value;\n");
      out.write("var submit_url = \"CassetteInfo.jsp?accessID=\"+ document.form1.accessID.value;\n");
      out.write("\t+ \"&userName=\"+ document.form1.userName.value \n");
      out.write("\t+ \"&searchBy=\" + val\n");
      out.write("\t+ \"&searchKey=\" + document.form1.searchKey.value\n");
      out.write("window.location.href = submit_url;\n");
      out.write("}\n");
      out.write("\n");
      out.write("//========================================================================\n");
      out.write("\n");
      out.write("function addCassette_onclick()\n");
      out.write("{\n");
      out.write("var submit_url= c_addCassetteURL;\n");
      out.write("submit_url+= \"?accessID=\"+ document.form1.accessID.value;\n");
      out.write("var x= document.form1.userName.value;\n");
      out.write("submit_url+= \"&userName=\"+ x;\n");
      out.write("window.location.href = submit_url;\n");
      out.write("}\n");
      out.write("\n");
      out.write("// client side script\n");
      out.write("//========================================================================\n");
      out.write("//========================================================================\n");
      out.write("//-->\n");
      out.write("</SCRIPT>\n");
      out.write("\n");
      out.write("<FORM id=\"form1\" method=\"post\" name=\"form1\">\n");
      out.write("<INPUT name=\"accessID\" type=\"hidden\" value=\"");
      out.print( s_accessID);
      out.write("\" />\n");
      out.write("<INPUT name=\"userName\" type=\"hidden\" value=\"");
      out.print( s_userName);
      out.write("\" />\n");
      out.write("<P>\n");
 emitUserName( s_userID, s_hasStaffPrivilege); 
      out.write("\n");
      out.write("<BR>\n");
      out.write("<FONT size=\"-1\">\n");
      out.write("Change the\n");
      out.write("<A class=\"clsLinkX\" HREF=\"loginForm.jsp\">\n");
      out.write("Login</A> if your user name does not appear above.\n");
      out.write("</FONT>\n");
      out.write("</P>\n");
      out.write("\n");
      out.write("\n");
      out.write("Download\n");
      out.write("&nbsp;<A class=\"clsLinkX\" HREF=\"data/templates/cassette_template.xls?accessID=");
      out.print( s_accessID);
      out.write("&userName=");
      out.print( s_userName);
      out.write("\">\n");
      out.write("SSRL cassette template</A>\n");
      out.write("&nbsp;or&nbsp;<A class=\"clsLinkX\" HREF=\"data/templates/puck_template.xls?accessID=");
      out.print( s_accessID);
      out.write("&userName=");
      out.print( s_userName);
      out.write("\">\n");
      out.write("Puck adapter template</A>\n");
      out.write("<BR>\n");
      out.write("<br/>\n");
      out.write("\n");
      out.write("<table>\n");
      out.write("<tr>\n");
      out.write("<td>\n");
      out.write("Create New Entry:\n");
      out.write("</td>\n");
      out.write("<td>\n");
      out.write("<input type=\"button\"\n");
      out.write("\tvalue=\"Upload Spreadsheet\"\n");
      out.write("\tclass=\"clsButton\"\n");
      out.write("\tonclick=\"uploadCassette_onclick()\" />\n");
      out.write("</td>\n");
      out.write("<td>\n");
      out.write("<input type=\"button\"\n");
      out.write("\tvalue=\"Use Default Spreadsheet\"\n");
      out.write("\tclass=\"clsButton\"\n");
      out.write("\tonclick=\"addCassette_onclick()\" />\n");
      out.write("<td>\n");
      out.write("</tr>\n");
      out.write("</table>\n");
      out.write("\n");
 String err = (String)request.getSession().getAttribute("error");
   request.getSession().removeAttribute("error");
   if (err != null) { 
      out.write("\n");
      out.write("<p style=\"color:red\">");
      out.print( err );
      out.write("</p>   \n");
 } // if err 
      out.write("\n");
      out.write("\n");
      out.write("<P>\n");
      out.write("\n");
 
	String cassetteDir = getConfigValue("cassetteDir");
	
	
	String searchBy = request.getParameter("searchBy");
	String searchKey = request.getParameter("searchKey");
	
	if (searchBy != null)
		session.setAttribute("searchBy", searchBy);
	else
		searchBy = (String)session.getAttribute("searchBy");
		
	if (searchKey != null)
		session.setAttribute("searchKey", searchKey);
	else
		searchKey = (String)session.getAttribute("searchKey");
		
	if (searchBy == null)
		searchBy = "";
	
	if (searchKey == null)
		searchKey = "";
		
	String errMsg = "";
	if ((searchBy != null) && searchBy.equals("CassetteID")) {
		String allowed = "1234567890*";
		for (int i = 0; i < searchKey.length(); ++i) {
			if (allowed.indexOf(searchKey.charAt(i)) > -1)
				continue;
				
			errMsg = "Invalid search string for search by SIL ID.";
			break;
		}
	}
			
	Vector cassettes = null;
	try {
	if ((searchBy != null) && (searchBy.length() > 0) && (searchKey != null) && (searchKey.length() > 0)) {
		cassettes = s_db.getUserCassettes(s_userName, searchBy, searchKey);
	} else {
		cassettes = s_db.getUserCassettes(s_userName);
	}
	} catch (Exception e) {
		errMsg += " " + e.getMessage();
		cassettes = new Vector();
	}
	
	Vector beamlines = s_db.getBeamlines();
	Hashtable hash = gate.getProperties();
	String allowedBeamlines = "" + (String)hash.get("Auth.Beamlines");
	HashSet allowedBeamlineLookup = new HashSet();
	if (!allowedBeamlines.equals("ALL")) {
		StringTokenizer tok = new StringTokenizer(allowedBeamlines, ";");
		while (tok.hasMoreTokens()) {
			String bb = tok.nextToken();
			allowedBeamlineLookup.add(bb);
			allowedBeamlineLookup.add(bb.toUpperCase());
		}
		
	}

	int numRows = cassettes.size();

	int startRange = 0;
	int numShow = 20;
	try {
		String saved = (String)session.getAttribute("numShow");
		numShow = Integer.parseInt(saved);
	} catch (NumberFormatException e) {
		numShow = 20;
	}
	
	if ((s_numShow != null) && (s_numShow.length() > 0)) {
    		try {
		numShow = Integer.parseInt(s_numShow);
    		} catch (Exception e) {
    		}
	}
	

	int firstStart = 0;
	int lastStart = numShow*((int)numRows/numShow);
	
	if (lastStart >= numRows) {
		lastStart = lastStart - numShow;
		if (lastStart < 0)
			lastStart = 0;
	}
	
	if ((s_startRange != null) && (s_startRange.length() > 0)) {
    		try {
			startRange = Integer.parseInt(s_startRange);
    		} catch (Exception e) {
    		}
	} else {
		startRange = lastStart;
		String saved = (String)session.getAttribute("startRange");
		if (saved != null) {
			try {
				startRange = Integer.parseInt(saved);
			} catch (NumberFormatException e) {
				startRange = lastStart;
			}
		}
			
	}
	int prevStart = startRange - numShow;
	if (prevStart < 0)
		prevStart = firstStart;
		
	if (lastStart >= numRows) {
		lastStart = prevStart;
		startRange = lastStart;
		prevStart = startRange - numShow;
		if (prevStart < 0)
			prevStart = firstStart;
	}

	int nextStart = startRange + numShow;
	if (nextStart >= numRows)
		nextStart = lastStart;
		
	
	int endRange = startRange + numShow - 1;
	if (endRange >= numRows)
		endRange = numRows - 1;
		
	if (numRows <= numShow) {
		startRange = 0;
		endRange = numRows - 1;
	}
	
	int displayStartRange = startRange + 1;
	
	if (numRows == 0)
		displayStartRange = 0;
	
	int displayEndRange = endRange + 1;
	
	if (numRows == 0)
		displayEndRange = 0;
			
	String cassetteInfoURL = "CassetteInfo.jsp?accessID=" + s_accessID + "&userName=" + s_userName;
	String showSilURL = "showSil.jsp?accessID=" + s_accessID + "&userName=" + s_userName;
	String downloadSilURL = "servlet/sil/sil.xls?accessID=" + s_accessID + "&userName=" + s_userName;
	String downloadExcelURL = "servlet/excel/orginal.xls?impSessionID=" + s_accessID + "&impUser=" + s_userName
					+ "&impFilePath=" + cassetteDir + "/" + s_userName;
	String deleteCassetteURL = s_deleteCassetteURL + "?accessID="+ s_accessID +"&userName="+ s_userName +"&";
	
	String resultParamStr = "accessID=" + s_accessID + "&userName=" + s_userName;
	String orgParamStr = "impSessionID=" + s_accessID + "&impUser=" + s_userName 
			  + "&impFilePath=" + cassetteDir + "/" + s_userName;
			  
	String opt1Selected = searchBy.equals("CassetteID") ? "selected" : "";
	String opt2Selected = searchBy.equals("UploadFileName") ? "selected" : "";
	
	session.setAttribute("startRange", String.valueOf(startRange));
	session.setAttribute("numShow", String.valueOf(numShow));
	

      out.write('\n');
      out.write('\n');
 if ((errMsg != null) && (errMsg.length() > 0)) { 
      out.write("\n");
      out.write("<span style=\"color:red\">");
      out.print( errMsg );
      out.write("</span>\n");
 } 
      out.write("\n");
      out.write("<TABLE>\n");
      out.write("  <tr bgcolor=\"#E9EEF5\"><td colspan=\"9\" align=\"right\">\n");
      out.write("  <span style=\"float:left\">\n");
      out.write("  Search By: <select name=\"searchBy\">\n");
      out.write("  <option value=\"CassetteID\" ");
      out.print( opt1Selected );
      out.write(" />SIL ID\n");
      out.write("  <option value=\"UploadFileName\" ");
      out.print( opt2Selected );
      out.write(" />Uploaded Spreadsheet\n");
      out.write("  </select> \n");
      out.write("  Wildcard: <input type=\"text\" name=\"searchKey\" value=\"");
      out.print( searchKey );
      out.write("\"/> \n");
      out.write("  <input type=\"submit\" name=\"search\" value=\"Search\" onclick=\"search()\"/>\n");
      out.write("  </span>\n");
      out.write("  Cassettes ");
      out.print( displayStartRange );
      out.write(' ');
      out.write('-');
      out.write(' ');
      out.print( displayEndRange );
      out.write(" of ");
      out.print( numRows );
      out.write("\n");
      out.write("  [\n");
 if (numRows <= numShow) { 
      out.write("\n");
      out.write(" start | prev | next | last ]\n");
 } else {
   if (startRange == firstStart) {
      out.write("\n");
      out.write(" first | prev |\n");
 } else { 
      out.write("\n");
      out.write("    <a href=\"");
      out.print( cassetteInfoURL );
      out.write("&startRange=");
      out.print( firstStart );
      out.write("&numRows=");
      out.print( numShow );
      out.write("\">first</a> | \n");
      out.write("    <a href=\"");
      out.print( cassetteInfoURL );
      out.write("&startRange=");
      out.print( prevStart );
      out.write("&numRows=");
      out.print( numShow );
      out.write("\">prev</a> | \n");
 } 
      out.write('\n');
 if ((startRange == lastStart) || (nextStart >= numRows)) {
      out.write("\n");
      out.write(" next | last ]\n");
 } else { 
      out.write("\n");
      out.write("    <a href=\"");
      out.print( cassetteInfoURL );
      out.write("&startRange=");
      out.print( nextStart );
      out.write("&numRows=");
      out.print( numShow );
      out.write("\">next</a> | \n");
      out.write("    <a href=\"");
      out.print( cassetteInfoURL );
      out.write("&startRange=");
      out.print( lastStart );
      out.write("&numRows=");
      out.print( numShow );
      out.write("\">last</a> ]\n");
 } } 
      out.write("\n");
      out.write("  </tr>\n");
      out.write("  <TR BGCOLOR=\"#E9EEF5\">\n");
      out.write("\t<TH align=\"center\">SIL ID</TH>\n");
      out.write("\t<TH align=\"center\">Uploaded Spreadsheet</TH>\n");
      out.write("\t<TH align=\"center\">Upload Time</TH>\n");
      out.write("\t<TH align=\"center\">Cassette PIN</TH>\n");
      out.write("\t<TH colspan=\"4\" align=\"center\">Commands</TH>\n");
      out.write("\t<TH align=\"center\">Beamline</TH>\n");
      out.write("  </TR>\n");
 
   int count = 0;
   String optionStr = "";
   String isSelected = "";
   for (int i = startRange; i <= endRange; ++i) {
   	++count;
   	CassetteInfo cas = (CassetteInfo)cassettes.elementAt(i);
   	if ((count % 2) == 0) { 
      out.write("\n");
      out.write("  <tr bgcolor=\"#E9EEF5\">\n");
      } else { 
      out.write("\n");
      out.write("  <tr bgcolor=\"#bed4e7\">\n");
      }
	optionStr = "";
	for (int j = 0; j < beamlines.size(); ++j) {
		isSelected = "";
		BeamlineInfo bb = (BeamlineInfo)beamlines.elementAt(j);
		// Only display the beamline the user has access to.
		if (allowedBeamlines.equals("ALL") || 
		    allowedBeamlineLookup.contains(bb.getBeamlineName()) ||
		    (bb.getBeamlineName().equals("None"))) {
		   if (bb.getId() == cas.getBeamlineId()) {
			isSelected = "selected";
		   }
		   optionStr += " <option value=\"" + bb.getId() + "\""  + isSelected + ">" + bb.toString() + "</option>";
		}
	}
	String ttName = cas.getUploadFileName();
	String fRootName = cas.getFileName();
	String realFName = fRootName + "_src.xls";
	String fullPath = cassetteDir + "/" + s_userName + "/" + realFName;
	int pos1 = ttName.lastIndexOf("/");
	if (pos1 < 0)
		pos1 = 0;
	int pos2 = ttName.indexOf(".xls", pos1);
	if (pos2 < 0)
		fRootName = ttName.substring(pos1);
	else
		fRootName = ttName.substring(pos1, pos2);



      out.write("\n");
      out.write("    <td align=\"center\">");
      out.print( cas.getSilId() );
      out.write("</td>\n");
      out.write("    <td>");
      out.print( cas.getUploadFileName() );
      out.write("</td>\n");
      out.write("    <td>");
      out.print( cas.getUploadTime() );
      out.write("</td>\n");
      out.write("    <td align=\"center\">");
      out.print( cas.getCassettePin() );
      out.write("</td>\n");
      out.write("    <td><A class=\"clsLinkX\" href=\"");
      out.print( showSilURL );
      out.write("&silId=");
      out.print( cas.getSilId() );
      out.write("\">View/Edit</a></td>\n");
      out.write("    <td><A class=\"clsLinkX\" href=\"servlet/sil/");
      out.print( fRootName );
      out.write("_result.xls?");
      out.print( resultParamStr );
      out.write("&silId=");
      out.print( cas.getSilId() );
      out.write("\">Download Results</a></td>\n");
      out.write("    <td><A class=\"clsLinkX\" href=\"servlet/excel/");
      out.print( fRootName );
      out.write(".xls?fileName=");
      out.print( fullPath );
      out.write("\">Download Original Excel</a></td>\n");
      out.write("<!--    <td><A class=\"clsLinkX\" href=\"servlet/excel/");
      out.print( fRootName );
      out.write(".xls?");
      out.print( orgParamStr );
      out.write('/');
      out.print( realFName );
      out.write("\">Download Original Excel</a></td>-->\n");
      out.write("    <td><a href=\"");
      out.print( deleteCassetteURL );
      out.write("&forCassetteID=");
      out.print( cas.getSilId() );
      out.write("\">Delete</a></td>\n");
      out.write("    <td>\n");
      out.write("      <select id=\"beamline");
      out.print( cas.getSilId() );
      out.write("\" name=\"beamline");
      out.print( cas.getSilId() );
      out.write("\" onchange=\"beamline_onchange(&quot;beamline");
      out.print( cas.getSilId() );
      out.write("&quot;, ");
      out.print( cas.getSilId() );
      out.write(')');
      out.write('"');
      out.write('>');
      out.print( optionStr );
      out.write("</select>\n");
      out.write("    </td>\n");
      out.write("  </tr>\n");
 } 
      out.write("\n");
      out.write("</TABLE>\n");
      out.write("</P>\n");
      out.write("\n");
      out.write("</FORM>\n");
      out.write("\n");
      out.write("\n");
      out.write("For more information see the\n");
      out.write("<A class=\"clsLinkX\" HREF=\"help.jsp\">\n");
      out.write("Online Help</A>.\n");
      out.write("<BR>\n");
      out.write("<BR>\n");
      out.write("\n");
 if( s_hasStaffPrivilege )
{

      out.write("\n");
      out.write("<HR>\n");
      out.write("View cassettes assigned to \n");
      out.write("<A class=\"clsLinkX\" HREF=\"BeamlineInfo.jsp?accessID=");
      out.print( s_accessID);
      out.write("&userName=");
      out.print( s_userName);
      out.write("\">\n");
      out.write("beamlines</A>.\n");
      out.write("<BR>\n");

}

      out.write("\n");
      out.write("\n");
      out.write("</body>\n");
      out.write("</html>\n");
      out.write("\n");
      out.write("</body>\n");
      out.write("</html>\n");
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
