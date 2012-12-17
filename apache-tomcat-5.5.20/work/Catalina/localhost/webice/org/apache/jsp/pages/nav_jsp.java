package org.apache.jsp.pages;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import webice.beans.*;
import webice.beans.strategy.*;
import webice.beans.image.*;
import webice.beans.process.*;
import webice.beans.screening.*;
import webice.beans.autoindex.*;
import webice.beans.video.*;
import webice.beans.collect.*;
import java.util.Vector;

public final class nav_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {

  private static java.util.List _jspx_dependants;

  static {
    _jspx_dependants = new java.util.ArrayList(1);
    _jspx_dependants.add("/pages/common.jspf");
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
      out.write("<!-- Include file defining the tag libraries and beans instances -->\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("<!-- Bean instances -->\n");
      webice.beans.Client client = null;
      synchronized (session) {
        client = (webice.beans.Client) _jspx_page_context.getAttribute("client", PageContext.SESSION_SCOPE);
        if (client == null){
          client = new webice.beans.Client();
          _jspx_page_context.setAttribute("client", client, PageContext.SESSION_SCOPE);
        }
      }
      out.write("\n");
      out.write("<!-- jsp:useBean id=\"fileBrowser\" class=\"webice.beans.FileBrowser\" scope=\"session\" -->\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("<html>\n");
      out.write("<head>\n");
      out.write("<meta http-equiv=\"Expires\" content=\"0\"/>\n");
      out.write("<meta http-equiv=\"Pragma\" CONTENT=\"no-cache\"/>\n");
      out.write("<link rel=\"stylesheet\" type=\"text/css\" href=\"style/topstyle.css\" />\n");
      out.write("</head>\n");
      out.write("\n");

	String helpUrl = ServerConfig.getHelpUrl();
	
	if (helpUrl == null)
		helpUrl = "http://smb.slac.stanford.edu/facilities/remote_access/webice"; 

	String tab = client.getTab();
	if (tab.equals("preference")) {
		helpUrl += "/Preferences.html";
	} else if (tab.equals("image")) {
		helpUrl += "/Image_Viewer.html";
	} else if (tab.equals("strategy")) {
		helpUrl += "/Autoindex_strategy_calculat.html";
	} else if (tab.equals("autoindex")) {
		helpUrl += "/Autoindex_strategy_calculat.html";
	} else if (tab.equals("screening")) {
		helpUrl += "/Screening_Crystals.html";
	} else if (tab.equals("video")) {
		helpUrl += "/Beamline_Video.html";
	} else if (tab.equals("beamline")) {
		helpUrl += "/Beamline_status.html";
	} else if (tab.equals("collect")) {
		helpUrl += "/";
	} else if (tab.equals("beamline")) {
		helpUrl += "/Beamline_status.html";
	}
	

      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("<body>\n");
      out.write("<span style=\"float:right;font-size:80%;padding-right:10px\">\n");
      out.write("<a class=\"a_selected\" href=\"");
      out.print( helpUrl );
      out.write("\" target=\"WebIceHelp\"><span id=\"help\">Help</span></a>&nbsp;\n");
      out.write("<a href=\"Logout.do\" target=\"_parent\">Logout</a>\n");
      out.write("</span>\n");
      out.write("<img src=\"images/logo.png\" width=\"80\"/>\n");
 if (client.showWelcomePage()) { 
	if (client.getTab().equals("welcome")) { 
      out.write("\n");
      out.write("    <a class=\"selected\" href=\"ChangeTab.do?tab=welcome\" target=\"_parent\">Welcome</a>\n");
 } else { 
      out.write("\n");
      out.write("    <a class=\"unselected\" href=\"ChangeTab.do?tab=welcome\" target=\"_parent\">Welcome</a>\n");
 }} 
      out.write('\n');
      out.write('\n');
 //if (client.getLoggedin()) { 
      out.write('\n');
      out.write('\n');
 if (client.getTab().equals("image")) { 
      out.write("\n");
      out.write("    <a class=\"selected\" href=\"ChangeTab.do?tab=image\" target=\"_parent\">Image Viewer</a>\n");
 } else { 
      out.write("\n");
      out.write("    <a class=\"unselected\" href=\"ChangeTab.do?tab=image\" target=\"_parent\">ImageViewer</a>\n");
 } 
      out.write('\n');
      out.write('\n');
 if (client.getTab().equals("autoindex")) { 
      out.write("\n");
      out.write("    <a class=\"selected\" href=\"ChangeTab.do?tab=autoindex\" target=\"_parent\">Autoindex</a>\n");
 } else { 
      out.write("\n");
      out.write("    <a class=\"unselected\" href=\"ChangeTab.do?tab=autoindex\" target=\"_parent\">Autoindex</a>\n");
 } 
      out.write('\n');
      out.write('\n');
 if (client.getTab().equals("screening")) { 
      out.write("\n");
      out.write("    <a class=\"selected\" href=\"ChangeTab.do?tab=screening\" target=\"_parent\">Screening</a>\n");
 } else { 
      out.write("\n");
      out.write("    <a class=\"unselected\" href=\"ChangeTab.do?tab=screening\" target=\"_parent\">Screening</a>\n");
 } 
      out.write('\n');
      out.write('\n');
 if (client.getTab().equals("beamline")) { 
      out.write("\n");
      out.write("    <a class=\"selected\" href=\"ChangeTab.do?tab=beamline\" target=\"_parent\">Beamline</a>\n");
 	} else { 
      out.write("\n");
      out.write("    <a class=\"unselected\" href=\"ChangeTab.do?tab=beamline\" target=\"_parent\">Beamline</a>\n");
 } 
      out.write('\n');
      out.write('\n');
 if (client.getTab().equals("video")) { 
      out.write("\n");
      out.write("    <a class=\"selected\" href=\"ChangeTab.do?tab=video\" target=\"_parent\">Video</a>\n");
 } else { 
      out.write("\n");
      out.write("    <a class=\"unselected\" href=\"ChangeTab.do?tab=video\" target=\"_parent\">Video</a>\n");
 } 
      out.write('\n');
      out.write('\n');
 if (client.getTab().equals("preference")) { 
      out.write("\n");
      out.write("    <a class=\"selected\" href=\"ChangeTab.do?tab=preference\" target=\"_parent\">Preferences</a>\n");
 } else { 
      out.write("\n");
      out.write("    <a class=\"unselected\" href=\"ChangeTab.do?tab=preference\" target=\"_parent\">Preferences</a>\n");
 } 
      out.write("\n");
      out.write("\n");
      out.write("</body>\n");
      out.write("\n");
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
