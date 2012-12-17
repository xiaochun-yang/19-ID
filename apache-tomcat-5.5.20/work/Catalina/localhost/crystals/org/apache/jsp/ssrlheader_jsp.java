package org.apache.jsp;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import java.io.*;

public final class ssrlheader_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {


//==============================================================
//==============================================================
// currently not used

void includeMainMenu(JspWriter out)
{
        // Tomcat doesn't support the Serverside Include used to add the drop-down menu
        // to normal SMB page headers, so instead, we have to read the file in using code
        try {
            BufferedReader in = new BufferedReader(new FileReader("/home/webserverroot/public/menu/top_menu.html"));
            String menuLine = in.readLine();
            while (menuLine != null) {
                out.println(menuLine);
                menuLine = in.readLine();
            }
            in.close();
        }
        catch (FileNotFoundException e) {
        }
        catch (IOException e) {
        } 
}

//==============================================================
//==============================================================

  private static java.util.List _jspx_dependants;

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


// pageheader.jsp
// define the header line for web pages of the Crystal Cassette Tracking System
//

      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("<TABLE>\r\n");
      out.write("<TR>\r\n");
      out.write("<TD>\r\n");
      out.write("<A HREF=\"http://smb.slac.stanford.edu\">\r\n");
      out.write("<img src=\"ssrl2.gif\" border=\"0\"  height=\"65\" width=\"75\" ALT=\"Click here to SMB Main Page\" />\r\n");
      out.write("</A>\r\n");
      out.write("</TD>\r\n");
      out.write("<TD>\r\n");
      out.write("<H1>Sample Database</H1>\r\n");
      out.write("</TD>\r\n");
      out.write("</TR>\r\n");
      out.write("</TABLE>\r\n");
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
