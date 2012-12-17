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
import webice.beans.dcs.DcsConnectionManager;

public final class toolbar_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {

  private static java.util.List _jspx_dependants;

  static {
    _jspx_dependants = new java.util.ArrayList(3);
    _jspx_dependants.add("/pages/common.jspf");
    _jspx_dependants.add("/pages/beamline_selection_script.jspf");
    _jspx_dependants.add("/pages/beamline_selection_form.jspf");
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
      out.write("\n");
      out.write("<html>\n");
      out.write("\n");
      out.write("<head>\n");
      out.write("<link rel=\"stylesheet\" type=\"text/css\" href=\"style/mainstyle.css\" />\n");
      out.write("<script id=\"event\" language=\"javascript\">\n");
      out.write("function beamline_onchange() {\n");
      out.write("    eval(\"i = document.beamlineForm.beamline.selectedIndex\");\n");
      out.write("    eval(\"x= document.beamlineForm.beamline.options[i].value\");\n");
      out.write("    if (x == \"\")\n");
      out.write("    \tparent.location.replace(\"Disconnect.do\");\n");
      out.write("    else\n");
      out.write("    \tparent.location.replace(\"Connect.do?beamline=\" + x);\n");
      out.write("\n");
      out.write("}\n");
      out.write("\n");
      out.write("</script>\n");
      out.write("\n");
      out.write("</head>\n");
      out.write("\n");
      out.write("<body class=\"toolbar_body\">\n");
      out.write("<span style=\"float:right\" class=\"small\">\n");
      out.write("<form name=\"beamlineForm\" target=\"_parent\" action=\"Connect.do\" >\n");
      out.write("Beamline:<select name=\"beamline\" onchange=\"beamline_onchange()\">\n");
 if (!client.isConnectedToBeamline()) { 
      out.write("\n");
      out.write("  <option value=\"\" selected>Select beamline\n");
 } else { 
      out.write("\n");
      out.write("  <option value=\"\">Disconnect\n");
 }

   Vector beamlines = client.getAvailableBeamlines();
   for (int i = 0; i < beamlines.size(); ++i) {
   		String bl = (String)beamlines.elementAt(i);
   		if (client.getBeamline().equals(bl)) {

      out.write("\n");
      out.write("\t<option value=\"");
      out.print( bl );
      out.write("\" selected >");
      out.print( bl );
      out.write('\n');
 } else { 
      out.write("\n");
      out.write("\t<option value=\"");
      out.print( bl );
      out.write('"');
      out.write(' ');
      out.write('>');
      out.print( bl );
      out.write('\n');
 } } 
      out.write("\n");
      out.write("\n");
      out.write("</select>\n");
      out.write("</form>\n");
      out.write("</span>\n");
      out.write("\n");
      out.write("Welcome, ");
      out.print( client.getUserName() );
      out.write(" \n");
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
