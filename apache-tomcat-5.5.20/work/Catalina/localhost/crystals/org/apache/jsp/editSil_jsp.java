package org.apache.jsp;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import sil.beans.*;
import javax.xml.transform.*;
import javax.xml.transform.stream.*;
import java.io.*;
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

public final class editSil_jsp extends org.apache.jasper.runtime.HttpJspBase
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


  private static java.util.List _jspx_dependants;

  static {
    _jspx_dependants = new java.util.ArrayList(1);
    _jspx_dependants.add("/../config.jsp");
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

	// disable browser cache
	response.setHeader("Expires","-1");
	String userName = "";
	JspWriter s_out;
	CassetteDB s_db = ctsdb;
	CassetteIO s_io = ctsio;

	out.clear();

	SilConfig silConfig = SilConfig.getInstance();

	String accessID = ServletUtil.getSessionId(request);

	userName= ServletUtil.getUserName(request);
	
	if (!checkAccessID(request, response))
		throw new Exception("Invalid session id " + accessID);
	
	String silId = request.getParameter("silId");

	String rowStr = request.getParameter("row");
	String command = request.getParameter("command");
	int id = Integer.parseInt(silId);
	String silFile = s_db.getCassetteFileName(id);
	String displayType = request.getParameter("displayType");

	if ((displayType == null) || (displayType.length() == 0))
		displayType = "display_src";

	String showImages = request.getParameter("showImages");
	if ((showImages == null) || (showImages.length() == 0))
		showImages = "hide";

	int row = -1;
	if ((rowStr != null) && (rowStr.length() > 0)) {
		row = Integer.parseInt(rowStr);
	}

	if (command.equals("All Cassettes") || command.equals("Sample Database")) {

		response.sendRedirect("CassetteInfo.jsp?accessID="
							+ accessID + "&userName=" + userName);

	} else if (row > -1) {

		String path = silConfig.getCassetteDir() + userName +"/" + silFile + "_sil.xml";
		String xsltFile = silConfig.getTemplateDir() + "xsltSil2Html3.xsl";


		String[] paramArray = new String[1];
		paramArray[0]= userName;

		try
		{
			TransformerFactory tFactory = TransformerFactory.newInstance();
			Transformer transformer = tFactory.newTransformer( new StreamSource( xsltFile));
			transformer.setParameter("param1", accessID);
			transformer.setParameter("param2", userName);
			transformer.setParameter("param3", silFile);
			transformer.setParameter("param4", rowStr);
			transformer.setParameter("param5", displayType);
			transformer.setParameter("param6", showImages);

			String systemId = SilConfig.getInstance().getSilDtdUrl();
			StreamSource source = new StreamSource( new FileReader(path), systemId);
			StreamResult result = new StreamResult(out);
			transformer.transform( source, result);

		} catch (Exception e) {
			errMsg("ERROR in ShowSil.jsp: " + e.getMessage());
			errMsg(e);
			throw e;
		}

	} else {

		response.sendRedirect("showSil.jsp?accessID=" + accessID
							+ "&userName=" + userName
							+ "&silId=" + silId
							+ "&displayType=" + displayType
							+ "&showImages=" + showImages
							+ "&row=" + row);

	} // if command == "Show Cassette List"


      out.write('\n');
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
