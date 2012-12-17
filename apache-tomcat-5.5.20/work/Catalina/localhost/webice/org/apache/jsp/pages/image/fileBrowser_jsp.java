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
import java.util.Vector;

public final class fileBrowser_jsp extends org.apache.jasper.runtime.HttpJspBase
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
      out.write("<link rel=\"stylesheet\" type=\"text/css\" href=\"style/mainstyle.css\" />\n");
      out.write("</head>\n");
      out.write("<body class=\"mainBody\">\n");
      out.write("\n");

	
	ImageViewer viewer = client.getImageViewer();
	FileBrowser fileBrowser = viewer.getFileBrowser();
	String wantedDir = viewer.getImageDir();
	String curDir = fileBrowser.getDirectory();
	String defaultDir = client.getUserImageRootDir();

  	String err = (String)request.getAttribute("error");
	
	if (err == null) {
		if (!wantedDir.equals(curDir)) {
			try {
				fileBrowser.changeDirectory(wantedDir);
				curDir = fileBrowser.getDirectory();
			} catch (Exception e) {
				err = "Cannot change directory to " + wantedDir
					+ " because " + e.getMessage();
			}
		}
	}
	
	if (err == null) {


	Object dirs[] = fileBrowser.getSubDirectories();
	Object files[] = fileBrowser.getFiles();

      out.write('\n');
      out.write('\n');
      out.print( curDir );
      out.write(":&nbsp;<a href=\"reloadDirectory.do\">[Update]</a>&#160;\n");
      out.write("<a href=\"changeDirectory.do?file=");
      out.print( curDir );
      out.write("/..\">[Up]</a><br>\n");
      out.write("<table style=\"vertical-align:-5em\">\n");
 for (int i = 0; i < dirs.length; ++i) {
	FileInfo file = (FileInfo)dirs[i]; 
      out.write("\n");
      out.write("\t<tr>\n");
      out.write("\t<td>");
      out.print( file.permissions );
      out.write("</td>\n");
      out.write("\t<td><a href=\"changeDirectory.do?file=");
      out.print( curDir );
      out.write('/');
      out.print( file.name );
      out.write('"');
      out.write('>');
      out.print( file.name );
      out.write("</a></td>\n");
      out.write("\t<td align=\"right\">");
      out.print( file.size );
      out.write("</td>\n");
      out.write("\t<td>");
      out.print( file.mtimeString );
      out.write("</td>\n");
      out.write("\t</tr>\n");
 } 
      out.write('\n');
 for (int i = 0; i < files.length; ++i) {
	FileInfo file = (FileInfo)files[i]; 
      out.write("\n");
      out.write("\t<tr>\n");
      out.write("\t<td>");
      out.print( file.permissions );
      out.write("</td>\n");
      out.write("\t<td><a href=\"loadImage.do?file=");
      out.print( curDir );
      out.write('/');
      out.print( file.name );
      out.write("\" target=\"imageViewerFrame\">");
      out.print( file.name );
      out.write("</a></td>\n");
      out.write("\t<td align=\"right\">");
      out.print( file.size );
      out.write("</td>\n");
      out.write("\t<td>");
      out.print( file.mtimeString );
      out.write("</td>\n");
      out.write("\t</tr>\n");
 } 
      out.write("\n");
      out.write("</table>\n");
      out.write("\n");
 } else { // err != null 
      out.write("\n");
      out.write("Go to default image dir <a href=\"changeDirectory.do?file=");
      out.print( defaultDir );
      out.write('"');
      out.write('>');
      out.print( defaultDir );
      out.write("</a>\n");
      out.write("<div class=\"error\">");
      out.print( err );
      out.write("</div>\n");
      out.write("\n");
 } 
      out.write("\n");
      out.write("</body>\n");
      out.write("</html>\n");
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
