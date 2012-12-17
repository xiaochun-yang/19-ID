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
import java.util.*;
import edu.stanford.slac.ssrl.authentication.utility.SMBGatewaySession;

public final class welcome_jsp extends org.apache.jasper.runtime.HttpJspBase
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
      out.write("\n");
      out.write("<html>\n");
      out.write("\n");
      out.write("\n");
      out.write("<head>\n");
      out.write("   <title>Web-Ice welcome page</title>\n");
      out.write("\n");
      out.write("   <link rel=\"stylesheet\" href=\"style/mainstyle.css\" type=\"text/css\">\n");
      out.write("</head>\n");
      out.write("\n");
      out.write("<body class=\"mainBody\">\n");
      out.write("<h1>Welcome to Web-Ice</h1>\n");
      out.write("\n");
      out.write("<p> Web-Ice is a set of tools for setting up and monitoring\n");
      out.write("experiments, and inspection and analysis of diffraction images and\n");
      out.write("sample screening results. Here follows a quick guide to Web-Ice. \n");
      out.write("If you do not wish to see this\n");
      out.write("page upon login to Web-Ice, set the entry <b>Show Welcome Page</b> to <b>No</b>\n");
      out.write("in the General Configuration Preferences.\n");
      out.write("\n");
      out.write("<table cellpadding=\"8\">\n");
      out.write("<tr>\n");
      out.write("<td width=\"55%\" valign=\"top\">\n");
      out.write("\n");
      out.write("<h2>Navigating Web-Ice</h2>\n");
      out.write("\n");
      out.write("<p>The Web-Ice applications are arranged by\n");
      out.write("function under each of the following tabs :</p>\n");
      out.write("\n");
 //if (client.getLoggedin()) { 
      out.write("\n");
      out.write(" <table>\n");
      out.write(" <tr>\n");
      out.write("  \n");
      out.write(" <td width=\"25%\"> <b>ImageViewer</b></td>\n");
      out.write(" <td>Inspection and analysis of diffraction images.</td>\n");
      out.write("\n");
      out.write(" </tr>\n");
      out.write(" <tr>\n");
      out.write("\n");
      out.write(" <td> <b>Autoindex</b></td> <td>Test image\n");
      out.write("    collection (optional), autoindexing and experiment strategy\n");
      out.write("    calculation</td>\n");
      out.write(" \n");
      out.write(" </tr>\n");
      out.write(" <tr>\n");
      out.write("\n");
      out.write(" <td><b>Screening</b> </td><td> Inspection of\n");
      out.write("    high throughput screening results</td>\n");
      out.write("    \n");
      out.write(" </tr>\n");
      out.write(" <tr>\n");
      out.write("\n");
      out.write(" <td><b>Video</b> </td><td>Access to live\n");
      out.write(" video from the beamline cameras</td>\n");
      out.write(" \n");
      out.write(" </tr>\n");
      out.write(" <tr>\n");
      out.write("\n");
      out.write(" ");
  if (client.isConnectedToBeamline() && (client.getUser().equals("penjitk") || client.getUser().equals("ana"))) { 
      out.write("\n");
      out.write("  <td><b>Beamline</b> </td><td>\n");
      out.write("  Tools to monitor the experiment (data collection status, and\n");
      out.write("  beamline video)</td>\n");
 } 
      out.write("\n");
      out.write("\n");
      out.write("  </tr>\n");
      out.write("  <tr>\n");
      out.write("  \n");
      out.write("  <td> <b>Preferences</b> </td><td>Setting up\n");
      out.write("    preferences for the Web-Ice interface</td>\n");
      out.write("  \n");
      out.write("  </tr>\n");
      out.write("</table>  \n");
      out.write("\n");
      out.write("<p>Tabs and navigation links and buttons are activated by left-clicking\n");
      out.write("on them. The current selection is highlighted.</p>\n");
      out.write("\n");
      out.write("</td>\n");
      out.write("\n");
      out.write("<td width=\"45%\" valign=\"top\">\n");
      out.write("\n");
      out.write("<h2>Connecting to a beamline</h2>\n");
      out.write("\n");
      out.write("<p>Although data analysis and inspection tools are available to users\n");
      out.write("at any time, some applications require connection to a beamline and \n");
      out.write("are only active during beamtime. Users can connect to their beamline by using the beamline selection menu\n");
      out.write("(inactive below):  \n");
      out.write("<form name=\"beamlineForm\" target=\"_parent\" action=\"Connect.do\" >\n");
      out.write("      <select name=\"beamline\" onchange=\"beamline_onchange()\">\n");
      out.write("      ");
 if (!client.isConnectedToBeamline()) { 
      out.write("\n");
      out.write("      <option value=\"\" selected >Select beamline\n");
      out.write("      ");
 }

      Vector beamlines = client.getAvailableBeamlines();
      for (int i = 0; i < beamlines.size(); ++i) {
                String bl = (String)beamlines.elementAt(i);
                if (client.getBeamline().equals(bl)) {
		
      out.write("\n");
      out.write("\t\t<option value=\"");
      out.print( bl );
      out.write("\" selected >");
      out.print( bl );
      out.write('\n');
      out.write('	');
      out.write('	');
 } else { 
      out.write("\n");
      out.write("\t\t<option value=\"");
      out.print( bl );
      out.write('"');
      out.write(' ');
      out.write('>');
      out.print( bl );
      out.write("\n");
      out.write("      ");
 } } 
      out.write("\n");
      out.write("      </select>\n");
      out.write("</form>\n");
 if (client.isConnectedToBeamline()) { 
      out.write("\n");
      out.write("To disconnect from the beamline, use the disconnect button (inactive below):\n");
      out.write("<form>\n");
      out.write("<input type=\"submit\" value=\"Disconnect\" />\n");
      out.write("</form>\n");
 } 
      out.write("\n");
      out.write("\n");
      out.write("<h2>Web-Ice Documentation</h2>\n");
      out.write("\n");
      out.write("<p> The <a href=\"\">Help</a> link in the top right corner links to\n");
      out.write("the on-line documentation for the selected Web-Ice tab on a separate\n");
      out.write("window. An information icon <b id=\"help\">i</b> is used to link\n");
      out.write("to information on a specific item.</p>\n");
      out.write("\n");
      out.write("</td>\n");
      out.write("</tr>\n");
      out.write("</table>\n");
      out.write("\n");
      out.write("\n");
      out.write("</body>\n");
      out.write("</html>\n");
      out.write("\n");
      out.write("\n");
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
