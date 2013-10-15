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

public final class help_jsp extends org.apache.jasper.runtime.HttpJspBase
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

      out.write("<HTML>\r\n");
      out.write("<HEADER>\r\n");
      out.write("<TITLE>Sample Database</TITLE>\r\n");
      out.write("</HEADER>\r\n");
      out.write("<BODY>\r\n");
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
      out.write('\r');
      out.write('\n');

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
      out.write("<H2>Using the Web interface of the Sample Database</H2>\r\n");
      out.write("\r\n");
      out.write("<A HREF=\"#v4_5\">\r\n");
      out.write("v4.5 release note\r\n");
      out.write("</A>\r\n");
      out.write("\r\n");
      out.write("<BR>\r\n");
      out.write("<A HREF=\"#v4_3\">\r\n");
      out.write("v4.3 release note\r\n");
      out.write("</A>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("<A HREF=\"#downloadNetscape\">\r\n");
      out.write("How to download an Excel file with Netscape\r\n");
      out.write("</A>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("<A HREF=\"#downloadIE\">\r\n");
      out.write("How to download an Excel file with Microsoft Internet Explorer\r\n");
      out.write("</A>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("<A HREF=\"#edit\">\r\n");
      out.write("How to edit an Excel spreadsheet on a SSRL beamline machine\r\n");
      out.write("</A>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("<A HREF=\"#upload\">\r\n");
      out.write("How to upload an Excel file\r\n");
      out.write("</A>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("<A HREF=\"#bluice\">\r\n");
      out.write("How to make the current selection visible in the BLU-ICE Screening UI\r\n");
      out.write("</A>\r\n");
      out.write("<BR>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("For more information see the manuals:\r\n");
      out.write("<BR>\r\n");
      out.write("<A HREF=\"http://smb.slac.stanford.edu/public/users_guide/manual/manual/Using_SSRL_Automated_Mounti.html\">\r\n");
      out.write("High-Throughput Screening System\r\n");
      out.write("</A>\r\n");
      out.write("<BR>\r\n");
      out.write("<A HREF=\"http://smb.slac.stanford.edu/public/facilities/software/blu-ice/screen_tab.html\">\r\n");
      out.write("BLU-ICE Screening UI\r\n");
      out.write("</A>\r\n");
      out.write("<BR>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("<HR>\r\n");
      out.write("<H3><A NAME=\"v4_5\">\r\n");
      out.write("v4.5 release note:\r\n");
      out.write("</A></H3>\r\n");
      out.write("<ul>\r\n");
      out.write("<li>Puck adapter template is now available.</li>\r\n");
      out.write("</ul>\r\n");
      out.write("<BR>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("<HR>\r\n");
      out.write("<H3><A NAME=\"v4_3\">\r\n");
      out.write("v4.3 release note:\r\n");
      out.write("</A></H3>\r\n");
      out.write("<ul>\r\n");
      out.write("<li>During upload, the spreadsheet maybe modified to ensure that Port, CrystalID and Directory\r\n");
      out.write("columns are valid.</li>\r\n");
      out.write("<li>Some crystal data in the uploaded spreadsheet can be edited and saved using web browser.</li>\r\n");
      out.write("<li>Crystal scoring results generated during screening are stored in the uploaded spreadsheet.</li>\r\n");
      out.write("<li>Both modified and original spreadsheet are downloadable.</li>\r\n");
      out.write("<li>User can assign a spreadsheet to a beamline in a single step using the web browser. The\r\n");
      out.write("spreadsheet will be loaded into BluIce automatically.</li>\r\n");
      out.write("</ul>\r\n");
      out.write("<BR>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("<HR>\r\n");
      out.write("<H3><A NAME=\"downloadNetscape\">\r\n");
      out.write("How to download an Excel file with Netscape:\r\n");
      out.write("</A></H3>\r\n");
      out.write("On the Screening System Database Page <strong>right-click</strong> the hyperlink \"Download Excel file\"\r\n");
      out.write("or \"Download Original Excel File\" for the corresponding cassette. \"Download Excel file\" downloads\r\n");
      out.write("the spreadsheet that is edited via the web browser and contains crystal scoring results.\r\n");
      out.write("\"Download Original Excel File\" downloads the original spreadsheet that the user uploaded.\r\n");
      out.write("<BR>\r\n");
      out.write("In the popup menu select \"Save Link As ...\".\r\n");
      out.write("<BR>\r\n");
      out.write("In the dialog \"Save As...\" select \"Source\" as the <strong>Format of the Saved Document</strong>,\r\n");
      out.write("navigate to the correct directory and press \"OK\".\r\n");
      out.write("<BR>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("<HR>\r\n");
      out.write("<H3><A NAME=\"downloadIE\">\r\n");
      out.write("How to download an Excel file with Microsoft Internet Explorer:\r\n");
      out.write("</A></H3>\r\n");
      out.write("On the Screening System Database Page <strong>right-click</strong> the hyperlink \"Download Excel file\"\r\n");
      out.write("or \"Download Original Excel File\"for the corresponding\r\n");
      out.write("cassette.\r\n");
      out.write("<BR>\r\n");
      out.write("In the popup menu select \"Save Target As ...\".\r\n");
      out.write("<BR>\r\n");
      out.write("In the dialog \"Save As...\" select \"Microsoft Excel Worksheet\" as the <strong>Save as type</strong>,\r\n");
      out.write("navigate to the correct directory and press \"Save\".\r\n");
      out.write("<BR>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("<HR>\r\n");
      out.write("<H3><A NAME=\"#edit\">\r\n");
      out.write("How to edit an Excel spreadsheet on a SSRL beamline machine via the web browser:\r\n");
      out.write("</A></H3>\r\n");
      out.write("Click \"View/Edit\" link on the cassette list page.\r\n");
      out.write("<BR>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("<HR>\r\n");
      out.write("<H3><A NAME=\"#edit\">\r\n");
      out.write("How to edit an Excel spreadsheet on a SSRL beamline machine using MS Excel or Star Office:\r\n");
      out.write("</A></H3>\r\n");
      out.write("If you want to use Microsoft software to edit the spreadsheet during you beamtime at SSRL,\r\n");
      out.write("you will have to bring your own laptop.\r\n");
      out.write("<BR>\r\n");
      out.write("Alternatively, you can run Netscape or Mozilla from the SGI beamline computers and\r\n");
      out.write("launch StarOffice from the \"Download Excel File...\" link in the screening database interface.\r\n");
      out.write("<BR>\r\n");
      out.write("You can also save the file to your own directories  as described <A HREF=\"#downloadNetscape\"> above</A> and\r\n");
      out.write("run StarOffice from the Unix command line:\r\n");
      out.write("<BR>\r\n");
      out.write("<strong>\r\n");
      out.write("&gt; soffice 'filename.xls'\r\n");
      out.write("</strong>\r\n");
      out.write("<BR>\r\n");
      out.write("The first time you run this program,\r\n");
      out.write("you will get some pop-up windows to generate some files in your home directory.\r\n");
      out.write("Select the defaults and click on \"next\" until the installation is complete.\r\n");
      out.write("<BR>\r\n");
      out.write("Once you have finished editing the spreadsheet,\r\n");
      out.write("save it to your home or data directory as a Microsoft Excel 97/2000/XP file type.\r\n");
      out.write("<BR>\r\n");
      out.write("For more information on this software, see the\r\n");
      out.write("<A HREF=\"http://www.openoffice.org/\">\r\n");
      out.write("OpenOffice</A> site.\r\n");
      out.write("<BR>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("<HR>\r\n");
      out.write("<H3><A NAME=\"upload\">\r\n");
      out.write("How to upload an Excel file:\r\n");
      out.write("</A></H3>\r\n");
      out.write("Make sure that the upload file is in Microsoft Excel format and is based on this\r\n");
      out.write("<A HREF=\"cassette_template.xls\">\r\n");
      out.write("template</A>.\r\n");
      out.write("<BR>\r\n");
      out.write("On Screening System Database page click the hyperlink \"Upload new file...\" for the corresponding\r\n");
      out.write("cassette.\r\n");
      out.write("<BR>\r\n");
      out.write("On the Upload Excel File page click the \"Browse\" button.\r\n");
      out.write("<BR>\r\n");
      out.write("In the dialog \"Choose File\" make sure that the <strong>Filter</strong> is \"*.*\" or \"*.xls\", navigate to the Excel file, select the Excel file and press \"Open\".\r\n");
      out.write("<BR>\r\n");
      out.write("Enter the correct spreadsheet name.\r\n");
      out.write("Please note that generally the spreadsheet name is not the same as the file name.\r\n");
      out.write("In most cases is the spreadsheet name \"Sheet1\" but Microsoft Excel gives you the option to change it.\r\n");
      out.write("Please use only alphanumeric characters for the spreadsheet name and do not use any space characters.\r\n");
      out.write("<BR>\r\n");
      out.write("Click the \"Upload\" button.\r\n");
      out.write("<BR>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("<HR>\r\n");
      out.write("<H3><A NAME=\"bluice\">\r\n");
      out.write("How to make the current selection visible in the BLU-ICE Screening UI:\r\n");
      out.write("</A></H3>\r\n");
      out.write("On <A HREF=\"CassetteInfo.jsp\">Screening System Database</A> page: Make sure that you have selected the correct beamline.\r\n");
      out.write("<BR>\r\n");
      out.write("In the screening UI at the beamline: <strong>Dismount</strong> the current crystal and press the <strong>\"Update\"</strong> button.\r\n");
      out.write("<BR>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("<HR>\r\n");
      out.write("<A HREF=\"CassetteInfo.jsp\">\r\n");
      out.write("Back</A> to the Screening System Database.\r\n");
      out.write("<BR>\r\n");
      out.write("<BR>\r\n");
      out.write("\r\n");
      out.write("</BODY>\r\n");
      out.write("</HTML>\r\n");
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
