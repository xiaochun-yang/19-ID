package org.apache.jsp.pages.image;

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

public final class imageCrystal_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {

  private static java.util.List _jspx_dependants;

  static {
    _jspx_dependants = new java.util.ArrayList(2);
    _jspx_dependants.add("/pages/common.jspf");
    _jspx_dependants.add("/pages/image/imageInfoNav.jspf");
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
      out.write("<html>\n");
      out.write("<head>\n");
      out.write("<link rel=\"stylesheet\" type=\"text/css\" href=\"style/mainstyle.css\" />\n");
      out.write("</head>\n");
      out.write("\n");
      out.write("<body class=\"mainBody\">\n");
      out.write("\n");
 ImageViewer viewer = client.getImageViewer();
	String s = viewer.getCrystalJpegUrl();

      out.write('\n');
 String tab = viewer.getInfoTab(); 
      out.write('\n');
      out.write('\n');
 if (tab.equals(ImageViewer.TAB_HEADER)) { 
      out.write("\n");
      out.write("    <span class=\"tab_white selected\"><a class=\"a_selected\"\n");
      out.write("\thref=\"ImageInfoChangeTab.do?tab=");
      out.print( ImageViewer.TAB_HEADER );
      out.write("\">Header</a></span>\n");
 } else { 
      out.write("\n");
      out.write("\t<span class=\"tab_white unselected\"><a class=\"a_unselected\"\n");
      out.write("\thref=\"ImageInfoChangeTab.do?tab=");
      out.print( ImageViewer.TAB_HEADER );
      out.write("\">Header</a></span>\n");
 } 
      out.write('\n');
      out.write('\n');
 if (tab.equals(ImageViewer.TAB_ANALYSE)) { 
      out.write("\n");
      out.write("   <span class=\"tab_white selected\"><a class=\"a_selected\"\n");
      out.write("    href=\"ImageInfoChangeTab.do?tab=");
      out.print( ImageViewer.TAB_ANALYSE );
      out.write("\" target=\"_parent\">Spot Statistics</a></span>\n");
 } else { 
      out.write("\n");
      out.write("    <span class=\"tab_white unselected\"><a class=\"a_unselected\"\n");
      out.write("    href=\"ImageInfoChangeTab.do?tab=");
      out.print( ImageViewer.TAB_ANALYSE );
      out.write("\" target=\"_parent\">Spot Statistics</a></span>\n");
 } 
      out.write('\n');
      out.write('\n');
 if (tab.equals(ImageViewer.TAB_CRYSTAL)) { 
      out.write("\n");
      out.write("    <span class=\"tab_right selected\"><a class=\"a_selected\" href=\"ImageInfoChangeTab.do?tab=");
      out.print( ImageViewer.TAB_CRYSTAL );
      out.write("\">Crystal Image</a></span>\n");
 } else { 
      out.write("\n");
      out.write("    <span class=\"tab_right unselected\"><a class=\"a_unselected\" href=\"ImageInfoChangeTab.do?tab=");
      out.print( ImageViewer.TAB_CRYSTAL );
      out.write("\">Crystal Image</a></span>\n");
 } 
      out.write("\n");
      out.write("<hr>\n");
      out.write("\n");
      out.write("\n");
      out.write("<div>\n");
      out.write("<style><!--PRE {line-height: 12pt; color:blue;font-size:10pt}--></style>\n");
 if ((s == null) || (s.length() == 0)) { 
      out.write("\n");
      out.write("Cannot find crystal jpeg file.\n");
 } else { 
      out.write("\n");
      out.write("<img src=\"");
      out.print( s );
      out.write("\" alt=\"Crystal Image\">\n");
 } 
      out.write("\n");
      out.write("</div>\n");
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
