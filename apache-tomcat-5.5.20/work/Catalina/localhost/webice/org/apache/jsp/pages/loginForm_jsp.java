package org.apache.jsp.pages;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import webice.beans.ServerConfig;

public final class loginForm_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {

  private static java.util.List _jspx_dependants;

  static {
    _jspx_dependants = new java.util.ArrayList(1);
    _jspx_dependants.add("/pages/smb_menu.html");
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

      out.write('\n');

	int port = ServerConfig.getWebicePortSecure();
	String login_url = "https://" + request.getServerName();
	if (port != 80)
		login_url += ":" + ServerConfig.getWebicePortSecure();
	
	login_url += request.getContextPath() + "/Login.do";
	

      out.write("\n");
      out.write("\n");
      out.write("<html>\n");
      out.write("<head>\n");
      out.write("<title>Webice Login Page</title>\n");
      out.write("\n");
      out.write("<link rel=\"STYLESHEET\" type=\"text/css\" href=\"https://smb.slac.stanford.edu/smb_mainstyle.css\">\n");
      out.write("\n");
      out.write("</style>\n");
      out.write("</head>\n");
      out.write("<body id=\"adorned\">\n");
      out.write("\n");
      out.write("<!--this is the beginning of the top banner table which includes a table for the sear\n");
      out.write("ch form-->\n");
      out.write("<table cellspacing=\"0\" style=\"table-layout:fixed\">\n");
      out.write("<tr>\n");
      out.write("    <td id=\"title\"><img src=\"https://smb.slac.stanford.edu/images/mctitle-2.jpg\" width=\"715\" height=\"54\"></td>\n");
      out.write("    <td id=\"search\"> \n");
      out.write("\n");
      out.write("    <!-- Search Google -->\n");
      out.write("    <form method=\"get\" action=\"http://www.google.com/custom\">\n");
      out.write("      <table border=\"0\" cellspacing=\"0\" bgcolor=\"#FFFFFF\" height=\"52\">\n");
      out.write("        <tr valign=\"top\">\n");
      out.write("        <td id=\"search\">Search:</td>\n");
      out.write("\t<td id=\"search\"><input type=\"text\" name=\"q\" size=\"15\" style=\"height:18px\" maxlength=\"255\" \n");
      out.write("\t  value=\"\"></td>\n");
      out.write("\t<td id=\"search\" align=\"left\">\n");
      out.write("\t<input type=\"image\" src=\"https://smb.slac.stanford.edu/images/go.gif\" align=\"left\" name=\"Google Search\">\n");
      out.write("\t<input type=\"hidden\" name=\"cof\" \n");
      out.write("\t  value=\"LW:715;L:http://smb.slac.stanford.edu/images/mctitle-2.jpg;LH:54;AH:left;AWFID:d96553f64c9708fa;\">\n");
      out.write("        <input type=\"hidden\" name=\"sitesearch\" value=\"smb.slac.stanford.edu\">\n");
      out.write("\t<input type=\"hidden\" name=\"domains\" value=\"smb.slac.stanford.edu\">\n");
      out.write("        </td>\n");
      out.write("        </tr>\n");
      out.write("        <tr>\n");
      out.write("        <td id=\"search\">&nbsp;\n");
      out.write("         </td>\n");
      out.write("                <td id=\"search\" colspan=\"2\" valign=\"top\"><!--\n");
      out.write("                <input type=\"radio\" name=\"sitesearch\" \n");
      out.write("                 value=\"smb.slac.stanford.edu\" checked>smb.slac.stanford.edu\n");
      out.write("                <input type=\"radio\" name=\"sitesearch\" value=\"\">\n");
      out.write("                 WWW&nbsp;<a href=\"http://www.google.com/search\"> <img src=\n");
      out.write("                 \"images/googl_25wht-all.gif\" alt=\"Google\" border=\"0\" width=\"50\" height=\"17\"></a>\n");
      out.write("                 -->\n");
      out.write("                powered by Google</td>\n");
      out.write("                </tr>\n");
      out.write("      </table>\n");
      out.write("    </form>\n");
      out.write("    <!-- Search Google End -->\n");
      out.write("        \n");
      out.write("</td>\n");
      out.write("</tr>\n");
      out.write("</table>\n");
      out.write("<table cellspacing=\"0\">\n");
      out.write("<tr id=\"content-top\">\n");
      out.write("<!--this is the end of the top banner table-->\n");
      out.write("\r\n");
      out.write("<td id=\"crumbs\" colspan=\"3\"><a id=\"current\"\r\n");
      out.write(" href=http://smb.slac.stanford.edu/public/index.shtml>Home</a> | <a\r\n");
      out.write("  href=http://smb.slac.stanford.edu/public/facilities/index.shtml>Facilities</a> | <a\r\n");
      out.write("  href=http://smb.slac.stanford.edu/public/users_guide/index.shtml>User Guide</a> | <a\r\n");
      out.write("  href=http://smb.slac.stanford.edu/public/schedule/index.shtml>Schedule</a> | <a\r\n");
      out.write("  href=http://smb.slac.stanford.edu/public/forms/index.shtml>Forms</a> | <a\r\n");
      out.write("  href=http://smb.slac.stanford.edu/public/research/index.shtml>Research</a> | <a\r\n");
      out.write("  href=http://smb.slac.stanford.edu/public/news/index.shtml>News</a> | \r\n");
      out.write("   <a\r\n");
      out.write("  href=http://smb.slac.stanford.edu/public/staff/index.php>Staff</a> | <a\r\n");
      out.write("  href=http://smb.slac.stanford.edu/public/links/index.shtml>Links</a>\r\n");
      out.write("  </td>\r\n");
      out.write("</tr></table>\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("<form method=\"post\" action=\"");
      out.print( login_url );
      out.write("\" target=\"_top\">\n");
 String err = (String)request.getAttribute("error");
   if (err != null) {

      out.write("\n");
      out.write("<div style=\"color:red\">");
      out.print( err );
      out.write("</div>\n");
 } 
      out.write("\n");
      out.write("<H2>Webice Login Page</H2>\n");
      out.write("\n");
      out.write("<table>\n");
      out.write("<tr><td width=\"100\">Login Name:</td><td align=\"left\"><input type=\"text\" name=\"userName\" value=\"\"/></td></tr>\n");
      out.write("<tr><td width=\"100\">Password:</td><td align=\"left\"><input type=\"password\" name=\"password\" value=\"\"/></td></tr>\n");
      out.write("<tr><td colspan=\"2\" align=\"left\"><input type=\"submit\" value=\"Login\"/></td></tr>\n");
      out.write("</table>\n");
      out.write("</form>\n");
      out.write("\n");
      out.write("Cookies must be enabled past this point. For Mozilla/Firefox, set <i>Preferences/Privacy/Cookies</i> option to <i>Allow cookies for the originating websites only</i> or <i>Allow sites to set cookies</i>. \n");
      out.write("For Internet Explorer, set <i>Tools/Internet Options/Privacy</i> option to <i>Medium</i>.\n");
      out.write("\n");
      out.write("<hr width=\"595\" size=\"1\" align=\"left\" />\n");
      out.write("Webice content questions and comments: <a href=\"mailto:ana@smb.slac.stanford.edu\">User Support</a>.<BR>\n");
      out.write("Technical questions and comments: <a href=\"mailto:webmaster@smb-mail.slac.stanford.edu\">Webmaster</a>.<BR>\n");
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
