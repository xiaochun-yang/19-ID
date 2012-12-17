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

public final class top_jsp extends org.apache.jasper.runtime.HttpJspBase
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

      out.write("<html>\n");
      out.write("\n");
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
      out.write("<head>\n");
      out.write("<link rel=\"stylesheet\" type=\"text/css\" href=\"style/mainstyle.css\" />\n");
      out.write("<title>WebIce</title>\n");
      out.write("</head>\n");
      out.write("\n");
 String err = (String)request.getAttribute("error");
   request.removeAttribute("error");
   if (err == null) { 
      out.write("\n");
      out.write("<frameset framespacing=\"0\" border=\"0\" frameborder=\"0\" rows=\"40,30,*\">\n");
      out.write("  <frame name=\"navFrame\" border=\"0\" frameborder=\"0\" scrolling=\"no\" noresize src=\"nav.do\"\n");
      out.write("  \t\tmarginwidth=\"0\" marginheight=\"5\">\n");
      out.write("  <frame name=\"toolbarFrame\" scrolling=\"no\" noresize src=\"toolbar.do\">\n");
      out.write("  <frame name=\"mainFrame\" border=\"0\" scrolling=\"auto\" frameborder=\"0\" src=\"SelectDisplay.do\" >\n");
      out.write("</frameset>\n");
      out.write("\n");
 } else { 
      out.write("\n");
      out.write("\n");
      out.write("<body>\n");
      out.write("<p class=\"error\">");
      out.print( err );
      out.write("</p>\n");
      out.write("<p>Click <a href=\"top.do\">here</a> to return to webice.</p>\n");
      out.write("</body>\n");
      out.write("\n");
 } 
      out.write("\n");
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
